/*
 * C bridge between MoonBit and orjson's vendored yyjson.
 *
 * Design
 * ------
 * - Parsing: the input is validated as UTF-8, parsed with yyjson, then the
 *   yyjson DOM is converted into a plain C tree (`mb_orjson_node`) that
 *   MoonBit converts into `Json` through O(1) accessor calls. Strings in a
 *   parse tree point into the yyjson document, which is kept alive in the
 *   parse handle.
 * - Serializing: MoonBit builds a `mb_orjson_node` tree through the builder
 *   functions, then `mb_orjson_dump` serializes it with orjson-compatible
 *   rules (indentation, key sorting, escaping, float formatting, newline).
 *   The tree is owned by the caller and must be released with
 *   `mb_orjson_tree_free`.
 * - Handles returned by `mb_orjson_parse_*` and `mb_orjson_dump` are plain
 *   malloc'd objects; MoonBit is responsible for recycling them with the
 *   matching `*_free` function. `#external type` values in MoonBit are raw
 *   pointers, so no GC finalizers are involved.
 */

#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <moonbit.h>

#include "yyjson_conf.h"
#include "../vendor/yyjson/yyjson.h"

/*============================================================================
 * Node type
 *==========================================================================*/

enum {
  MB_ORJSON_NULL = 0,
  MB_ORJSON_BOOL = 1,
  MB_ORJSON_INT = 2,
  MB_ORJSON_UINT = 3,
  MB_ORJSON_FLOAT = 4,
  MB_ORJSON_STRING = 5,
  MB_ORJSON_RAW = 6,
  MB_ORJSON_ARRAY = 7,
  MB_ORJSON_OBJECT = 8
};

typedef struct mb_orjson_node {
  int32_t type;
  int32_t _pad;
  union {
    int32_t boolean;
    int64_t i64;
    uint64_t u64;
    double f64;
    struct {
      char *ptr;
      size_t len;
    } str;
    struct {
      struct mb_orjson_node **items;
      size_t len;
      size_t cap;
    } arr;
    struct {
      struct mb_orjson_node **keys;
      struct mb_orjson_node **vals;
      size_t len;
      size_t cap;
    } obj;
  } u;
} mb_orjson_node;

#define MB_ERR_INVALID_STR "str is not valid UTF-8: surrogates not allowed"
#define MB_ERR_OOM "failed to allocate memory"
#define MB_ERR_RECURSION "Recursion limit reached"

/* Message of the most recent encode-tree building failure. */
static const char *mb_orjson_build_err = MB_ERR_OOM;

static void *mb_fail(const char *msg) {
  mb_orjson_build_err = msg;
  return NULL;
}

static char *mb_strdup(const char *s) {
  size_t len = strlen(s);
  char *r = (char *)malloc(len + 1);
  if (r) memcpy(r, s, len + 1);
  return r;
}

static mb_orjson_node *mb_node_new(int32_t type) {
  mb_orjson_node *n = (mb_orjson_node *)calloc(1, sizeof(mb_orjson_node));
  if (n) n->type = type;
  return n;
}

/* Free a subtree. `free_strings` is 1 for encode trees (strings are malloc'd)
 * and 0 for parse trees (strings point into the yyjson document). */
static void mb_node_free(mb_orjson_node *n, int32_t free_strings) {
  if (!n) return;
  switch (n->type) {
    case MB_ORJSON_STRING:
    case MB_ORJSON_RAW:
      if (free_strings) free(n->u.str.ptr);
      break;
    case MB_ORJSON_ARRAY: {
      for (size_t i = 0; i < n->u.arr.len; i++)
        mb_node_free(n->u.arr.items[i], free_strings);
      free(n->u.arr.items);
      break;
    }
    case MB_ORJSON_OBJECT: {
      for (size_t i = 0; i < n->u.obj.len; i++) {
        mb_node_free(n->u.obj.keys[i], free_strings);
        mb_node_free(n->u.obj.vals[i], free_strings);
      }
      free(n->u.obj.keys);
      free(n->u.obj.vals);
      break;
    }
    default:
      break;
  }
  free(n);
}

static int32_t mb_arr_push(mb_orjson_node *arr, mb_orjson_node *item) {
  if (arr->u.arr.len == arr->u.arr.cap) {
    size_t cap = arr->u.arr.cap ? arr->u.arr.cap * 2 : 4;
    mb_orjson_node **items =
        (mb_orjson_node **)realloc(arr->u.arr.items, cap * sizeof(*items));
    if (!items) return 0;
    arr->u.arr.items = items;
    arr->u.arr.cap = cap;
  }
  arr->u.arr.items[arr->u.arr.len++] = item;
  return 1;
}

static int32_t mb_obj_push(mb_orjson_node *obj, mb_orjson_node *key,
                           mb_orjson_node *val) {
  if (obj->u.obj.len == obj->u.obj.cap) {
    size_t cap = obj->u.obj.cap ? obj->u.obj.cap * 2 : 4;
    mb_orjson_node **keys =
        (mb_orjson_node **)realloc(obj->u.obj.keys, cap * sizeof(*keys));
    if (!keys) return 0;
    obj->u.obj.keys = keys;
    mb_orjson_node **vals =
        (mb_orjson_node **)realloc(obj->u.obj.vals, cap * sizeof(*vals));
    if (!vals) return 0;
    obj->u.obj.vals = vals;
    obj->u.obj.cap = cap;
  }
  obj->u.obj.keys[obj->u.obj.len] = key;
  obj->u.obj.vals[obj->u.obj.len] = val;
  obj->u.obj.len++;
  return 1;
}

/*============================================================================
 * String conversions
 *==========================================================================*/

/* Decode UTF-8 into a freshly allocated MoonBit string. The input must be
 * valid UTF-8 (yyjson output always is); invalid bytes defensively become
 * U+FFFD. */
static moonbit_string_t mb_mb_string_from_utf8(const char *s, size_t len) {
  size_t units = 0;
  for (size_t i = 0; i < len;) {
    unsigned char c = (unsigned char)s[i];
    if (c < 0x80) {
      units += 1;
      i += 1;
    } else if ((c & 0xE0) == 0xC0) {
      units += 1;
      i += 2;
    } else if ((c & 0xF0) == 0xE0) {
      units += 1;
      i += 3;
    } else if ((c & 0xF8) == 0xF0) {
      units += 2;
      i += 4;
    } else {
      units += 1;
      i += 1;
    }
  }
  moonbit_string_t r = moonbit_make_string_raw((int32_t)units);
  size_t w = 0;
  for (size_t i = 0; i < len;) {
    unsigned char c = (unsigned char)s[i];
    uint32_t cp = 0xFFFD;
    size_t n = 1;
    if (c < 0x80) {
      cp = c;
      n = 1;
    } else if ((c & 0xE0) == 0xC0 && i + 1 < len) {
      cp = ((uint32_t)(c & 0x1F) << 6) | ((unsigned char)s[i + 1] & 0x3F);
      n = 2;
    } else if ((c & 0xF0) == 0xE0 && i + 2 < len) {
      cp = ((uint32_t)(c & 0x0F) << 12) |
           ((uint32_t)((unsigned char)s[i + 1] & 0x3F) << 6) |
           ((unsigned char)s[i + 2] & 0x3F);
      n = 3;
    } else if ((c & 0xF8) == 0xF0 && i + 3 < len) {
      cp = ((uint32_t)(c & 0x07) << 18) |
           ((uint32_t)((unsigned char)s[i + 1] & 0x3F) << 12) |
           ((uint32_t)((unsigned char)s[i + 2] & 0x3F) << 6) |
           ((unsigned char)s[i + 3] & 0x3F);
      n = 4;
    }
    i += n;
    if (cp >= 0x10000) {
      cp -= 0x10000;
      r[w++] = (uint16_t)(0xD800 + (cp >> 10));
      r[w++] = (uint16_t)(0xDC00 + (cp & 0x3FF));
    } else {
      r[w++] = (uint16_t)cp;
    }
  }
  return r;
}

/* Encode UTF-16 (MoonBit string) into a freshly allocated, NUL-terminated
 * UTF-8 buffer. Returns NULL and sets *invalid on lone surrogates, or NULL
 * with *invalid = 0 on allocation failure. */
static char *mb_utf8_from_utf16(const uint16_t *s, int32_t len,
                                int32_t *out_len, int32_t *invalid) {
  *invalid = 0;
  char *buf = (char *)malloc((size_t)len * 4 + 1);
  if (!buf) return NULL;
  size_t w = 0;
  for (int32_t i = 0; i < len; i++) {
    uint32_t c = s[i];
    if (c >= 0xD800 && c <= 0xDBFF) {
      if (i + 1 < len && s[i + 1] >= 0xDC00 && s[i + 1] <= 0xDFFF) {
        uint32_t cp =
            0x10000 + ((c - 0xD800) << 10) + ((uint32_t)s[i + 1] - 0xDC00);
        buf[w++] = (char)(0xF0 | (cp >> 18));
        buf[w++] = (char)(0x80 | ((cp >> 12) & 0x3F));
        buf[w++] = (char)(0x80 | ((cp >> 6) & 0x3F));
        buf[w++] = (char)(0x80 | (cp & 0x3F));
        i++;
      } else {
        *invalid = 1;
        free(buf);
        return NULL;
      }
    } else if (c >= 0xDC00 && c <= 0xDFFF) {
      *invalid = 1;
      free(buf);
      return NULL;
    } else if (c < 0x80) {
      buf[w++] = (char)c;
    } else if (c < 0x800) {
      buf[w++] = (char)(0xC0 | (c >> 6));
      buf[w++] = (char)(0x80 | (c & 0x3F));
    } else {
      buf[w++] = (char)(0xE0 | (c >> 12));
      buf[w++] = (char)(0x80 | ((c >> 6) & 0x3F));
      buf[w++] = (char)(0x80 | (c & 0x3F));
    }
  }
  buf[w] = '\0';
  *out_len = (int32_t)w;
  return buf;
}

/* Strict UTF-8 validation (rejects surrogates, overlongs, > U+10FFFF and
 * truncated sequences), matching the check orjson performs before parsing. */
static int32_t mb_utf8_valid(const uint8_t *s, size_t len) {
  size_t i = 0;
  while (i < len) {
    uint8_t c = s[i];
    if (c < 0x80) {
      i += 1;
    } else if ((c & 0xE0) == 0xC0) {
      if (i + 1 >= len || (s[i + 1] & 0xC0) != 0x80) return 0;
      if (c < 0xC2) return 0;
      i += 2;
    } else if ((c & 0xF0) == 0xE0) {
      if (i + 2 >= len || (s[i + 1] & 0xC0) != 0x80 ||
          (s[i + 2] & 0xC0) != 0x80)
        return 0;
      if (c == 0xE0 && s[i + 1] < 0xA0) return 0;
      if (c == 0xED && s[i + 1] >= 0xA0) return 0;
      i += 3;
    } else if ((c & 0xF8) == 0xF0) {
      if (i + 3 >= len || (s[i + 1] & 0xC0) != 0x80 ||
          (s[i + 2] & 0xC0) != 0x80 || (s[i + 3] & 0xC0) != 0x80)
        return 0;
      if (c == 0xF0 && s[i + 1] < 0x90) return 0;
      if (c == 0xF4 && s[i + 1] >= 0x90) return 0;
      if (c > 0xF4) return 0;
      i += 4;
    } else {
      return 0;
    }
  }
  return 1;
}

/*============================================================================
 * Error formatting (orjson / CPython json.JSONDecodeError style)
 *==========================================================================*/

/* Format "{msg}: line {line} column {col} (char {pos})" where line/column/
 * char follow CPython's json.JSONDecodeError over the decoded text. */
static char *mb_format_error(const char *msg, const char *data,
                             size_t byte_pos) {
  size_t cp = 0;
  size_t newlines = 0;
  size_t last_nl = (size_t)-1;
  for (size_t i = 0; i < byte_pos; i++) {
    unsigned char c = (unsigned char)data[i];
    if ((c & 0xC0) != 0x80) {
      if (c == '\n') {
        newlines++;
        last_nl = cp;
      }
      cp++;
    }
  }
  size_t line = newlines + 1;
  size_t col = (last_nl == (size_t)-1) ? cp + 1 : cp - last_nl;
  size_t cap = strlen(msg) + 64;
  char *r = (char *)malloc(cap);
  if (!r) return mb_strdup(MB_ERR_OOM);
  snprintf(r, cap, "%s: line %llu column %llu (char %llu)", msg,
           (unsigned long long)line, (unsigned long long)col,
           (unsigned long long)cp);
  return r;
}

static int64_t mb_char_pos(const char *data, size_t byte_pos) {
  size_t cp = 0;
  for (size_t i = 0; i < byte_pos; i++) {
    if (((unsigned char)data[i] & 0xC0) != 0x80) cp++;
  }
  return (int64_t)cp;
}

/*============================================================================
 * Parsing
 *==========================================================================*/

typedef struct {
  int32_t ok;
  int32_t _pad;
  mb_orjson_node *root;
  yyjson_doc *doc;
  char *err;
  int64_t err_pos;
} mb_orjson_parse_result;

static mb_orjson_node *mb_dom_to_node(yyjson_val *v) {
  if (!v) return NULL;
  yyjson_type t = yyjson_get_type(v);
  if (t == YYJSON_TYPE_NULL) {
    return mb_node_new(MB_ORJSON_NULL);
  }
  if (t == YYJSON_TYPE_BOOL) {
    mb_orjson_node *n = mb_node_new(MB_ORJSON_BOOL);
    if (n) n->u.boolean = yyjson_get_bool(v) ? 1 : 0;
    return n;
  }
  if (t == YYJSON_TYPE_NUM) {
    yyjson_subtype st = yyjson_get_subtype(v);
    if (st == YYJSON_SUBTYPE_UINT) {
      mb_orjson_node *n = mb_node_new(MB_ORJSON_UINT);
      if (n) n->u.u64 = yyjson_get_uint(v);
      return n;
    }
    if (st == YYJSON_SUBTYPE_SINT) {
      mb_orjson_node *n = mb_node_new(MB_ORJSON_INT);
      if (n) n->u.i64 = yyjson_get_sint(v);
      return n;
    }
    mb_orjson_node *n = mb_node_new(MB_ORJSON_FLOAT);
    if (n) n->u.f64 = yyjson_get_real(v);
    return n;
  }
  if (t == YYJSON_TYPE_STR) {
    mb_orjson_node *n = mb_node_new(MB_ORJSON_STRING);
    if (!n) return NULL;
    n->u.str.ptr = (char *)yyjson_get_str(v);
    n->u.str.len = yyjson_get_len(v);
    return n;
  }
  if (t == YYJSON_TYPE_ARR) {
    size_t cnt = yyjson_arr_size(v);
    mb_orjson_node *n = mb_node_new(MB_ORJSON_ARRAY);
    if (!n) return NULL;
    for (size_t i = 0; i < cnt; i++) {
      mb_orjson_node *child = mb_dom_to_node(yyjson_arr_get(v, i));
      if (!child || !mb_arr_push(n, child)) {
        mb_node_free(child, 0);
        mb_node_free(n, 0);
        return NULL;
      }
    }
    return n;
  }
  if (t == YYJSON_TYPE_OBJ) {
    mb_orjson_node *n = mb_node_new(MB_ORJSON_OBJECT);
    if (!n) return NULL;
    yyjson_obj_iter iter = yyjson_obj_iter_with(v);
    yyjson_val *key;
    while ((key = yyjson_obj_iter_next(&iter))) {
      yyjson_val *val = yyjson_obj_iter_get_val(key);
      mb_orjson_node *k = mb_node_new(MB_ORJSON_STRING);
      if (k) {
        k->u.str.ptr = (char *)yyjson_get_str(key);
        k->u.str.len = yyjson_get_len(key);
      }
      mb_orjson_node *child = mb_dom_to_node(val);
      if (!k || !child || !mb_obj_push(n, k, child)) {
        mb_node_free(k, 0);
        mb_node_free(child, 0);
        mb_node_free(n, 0);
        return NULL;
      }
    }
    return n;
  }
  return NULL;
}

static mb_orjson_parse_result *mb_parse_impl(const char *data, size_t len) {
  mb_orjson_parse_result *res =
      (mb_orjson_parse_result *)calloc(1, sizeof(*res));
  if (!res) return NULL;
  if (len == 0) {
    res->err = mb_format_error("Input is a zero-length, empty document", "", 0);
    return res;
  }
  if (!mb_utf8_valid((const uint8_t *)data, len)) {
    res->err = mb_format_error(MB_ERR_INVALID_STR, "", 0);
    return res;
  }
  yyjson_read_err e;
  memset(&e, 0, sizeof(e));
  yyjson_doc *doc = yyjson_read_opts((char *)data, len, NULL, &e);
  if (!doc) {
    res->err = mb_format_error(e.msg ? e.msg : "unknown error", data, e.pos);
    res->err_pos = mb_char_pos(data, e.pos);
    return res;
  }
  mb_orjson_node *root = mb_dom_to_node(yyjson_doc_get_root(doc));
  if (!root) {
    yyjson_doc_free(doc);
    res->err = mb_strdup(MB_ERR_OOM);
    return res;
  }
  res->ok = 1;
  res->root = root;
  res->doc = doc;
  return res;
}

MOONBIT_EXPORT void *mb_orjson_parse_bytes(moonbit_bytes_t input) {
  int32_t len = Moonbit_array_length((void *)input);
  return mb_parse_impl((const char *)input, (size_t)len);
}

MOONBIT_EXPORT void *mb_orjson_parse_string(moonbit_string_t input) {
  int32_t len = Moonbit_array_length((void *)input);
  int32_t out_len = 0;
  int32_t invalid = 0;
  char *utf8 = mb_utf8_from_utf16(input, len, &out_len, &invalid);
  if (!utf8) {
    mb_orjson_parse_result *res =
        (mb_orjson_parse_result *)calloc(1, sizeof(*res));
    if (!res) return NULL;
    if (invalid) {
      res->err = mb_format_error(MB_ERR_INVALID_STR, "", 0);
    } else {
      res->err = mb_strdup(MB_ERR_OOM);
    }
    return res;
  }
  mb_orjson_parse_result *res = mb_parse_impl(utf8, (size_t)out_len);
  free(utf8);
  return res;
}

MOONBIT_EXPORT int64_t mb_orjson_parse_ok(void *handle) {
  mb_orjson_parse_result *res = (mb_orjson_parse_result *)handle;
  return res->ok ? 1 : 0;
}

MOONBIT_EXPORT void *mb_orjson_parse_root(void *handle) {
  return ((mb_orjson_parse_result *)handle)->root;
}

MOONBIT_EXPORT moonbit_string_t mb_orjson_parse_error(void *handle) {
  mb_orjson_parse_result *res = (mb_orjson_parse_result *)handle;
  const char *msg = res->err ? res->err : MB_ERR_OOM;
  return mb_mb_string_from_utf8(msg, strlen(msg));
}

MOONBIT_EXPORT int64_t mb_orjson_parse_error_pos(void *handle) {
  return ((mb_orjson_parse_result *)handle)->err_pos;
}

MOONBIT_EXPORT void mb_orjson_parse_free(void *handle) {
  mb_orjson_parse_result *res = (mb_orjson_parse_result *)handle;
  if (!res) return;
  mb_node_free(res->root, 0);
  if (res->doc) yyjson_doc_free(res->doc);
  free(res->err);
  free(res);
}

/*============================================================================
 * Node accessors (parse -> MoonBit)
 *==========================================================================*/

MOONBIT_EXPORT int64_t mb_orjson_node_type(void *node) {
  return ((mb_orjson_node *)node)->type;
}

MOONBIT_EXPORT int64_t mb_orjson_node_bool(void *node) {
  return ((mb_orjson_node *)node)->u.boolean;
}

MOONBIT_EXPORT int64_t mb_orjson_node_int(void *node) {
  return ((mb_orjson_node *)node)->u.i64;
}

MOONBIT_EXPORT uint64_t mb_orjson_node_uint(void *node) {
  return ((mb_orjson_node *)node)->u.u64;
}

MOONBIT_EXPORT double mb_orjson_node_float(void *node) {
  return ((mb_orjson_node *)node)->u.f64;
}

MOONBIT_EXPORT moonbit_string_t mb_orjson_node_string(void *node) {
  mb_orjson_node *n = (mb_orjson_node *)node;
  return mb_mb_string_from_utf8(n->u.str.ptr, n->u.str.len);
}

MOONBIT_EXPORT int64_t mb_orjson_node_size(void *node) {
  mb_orjson_node *n = (mb_orjson_node *)node;
  if (n->type == MB_ORJSON_ARRAY) return (int64_t)n->u.arr.len;
  if (n->type == MB_ORJSON_OBJECT) return (int64_t)n->u.obj.len;
  return 0;
}

MOONBIT_EXPORT void *mb_orjson_node_array_get(void *node, int64_t index) {
  mb_orjson_node *n = (mb_orjson_node *)node;
  if (index < 0 || (size_t)index >= n->u.arr.len) return NULL;
  return n->u.arr.items[index];
}

MOONBIT_EXPORT moonbit_string_t mb_orjson_node_object_key(void *node,
                                                          int64_t index) {
  mb_orjson_node *n = (mb_orjson_node *)node;
  if (index < 0 || (size_t)index >= n->u.obj.len) {
    return moonbit_make_string_raw(0);
  }
  mb_orjson_node *k = n->u.obj.keys[index];
  return mb_mb_string_from_utf8(k->u.str.ptr, k->u.str.len);
}

MOONBIT_EXPORT void *mb_orjson_node_object_get(void *node, int64_t index) {
  mb_orjson_node *n = (mb_orjson_node *)node;
  if (index < 0 || (size_t)index >= n->u.obj.len) return NULL;
  return n->u.obj.vals[index];
}

/*============================================================================
 * Tree building (MoonBit -> encode tree)
 *==========================================================================*/

MOONBIT_EXPORT int64_t mb_orjson_handle_is_null(void *handle) {
  return handle == NULL;
}

MOONBIT_EXPORT int64_t mb_orjson_node_is_null(void *node) {
  return node == NULL;
}

MOONBIT_EXPORT moonbit_string_t mb_orjson_build_error(void) {
  return mb_mb_string_from_utf8(mb_orjson_build_err,
                                strlen(mb_orjson_build_err));
}

MOONBIT_EXPORT void *mb_orjson_build_null(void) {
  return mb_node_new(MB_ORJSON_NULL);
}

MOONBIT_EXPORT void *mb_orjson_build_bool(int64_t value) {
  mb_orjson_node *n = mb_node_new(MB_ORJSON_BOOL);
  if (n) n->u.boolean = value ? 1 : 0;
  return n;
}

MOONBIT_EXPORT void *mb_orjson_build_int(int64_t value) {
  mb_orjson_node *n = mb_node_new(MB_ORJSON_INT);
  if (n) n->u.i64 = value;
  return n;
}

MOONBIT_EXPORT void *mb_orjson_build_uint(uint64_t value) {
  mb_orjson_node *n = mb_node_new(MB_ORJSON_UINT);
  if (n) n->u.u64 = value;
  return n;
}

MOONBIT_EXPORT void *mb_orjson_build_float(double value) {
  mb_orjson_node *n = mb_node_new(MB_ORJSON_FLOAT);
  if (n) n->u.f64 = value;
  return n;
}

static void *mb_build_string_impl(moonbit_string_t s, int32_t type) {
  int32_t len = Moonbit_array_length((void *)s);
  int32_t out_len = 0;
  int32_t invalid = 0;
  char *utf8 = mb_utf8_from_utf16(s, len, &out_len, &invalid);
  if (!utf8) return mb_fail(invalid ? MB_ERR_INVALID_STR : MB_ERR_OOM);
  mb_orjson_node *n = mb_node_new(type);
  if (!n) {
    free(utf8);
    return mb_fail(MB_ERR_OOM);
  }
  n->u.str.ptr = utf8;
  n->u.str.len = (size_t)out_len;
  return n;
}

MOONBIT_EXPORT void *mb_orjson_build_string(moonbit_string_t s) {
  return mb_build_string_impl(s, MB_ORJSON_STRING);
}

MOONBIT_EXPORT void *mb_orjson_build_raw(moonbit_string_t s) {
  return mb_build_string_impl(s, MB_ORJSON_RAW);
}

MOONBIT_EXPORT void *mb_orjson_build_array(void) {
  return mb_node_new(MB_ORJSON_ARRAY);
}

MOONBIT_EXPORT void *mb_orjson_build_object(void) {
  return mb_node_new(MB_ORJSON_OBJECT);
}

MOONBIT_EXPORT int64_t mb_orjson_array_push(void *arr, void *item) {
  if (!arr || !item) return -2;
  if (!mb_arr_push((mb_orjson_node *)arr, (mb_orjson_node *)item)) {
    mb_orjson_build_err = MB_ERR_OOM;
    return -2;
  }
  return 0;
}

MOONBIT_EXPORT int64_t mb_orjson_object_put(void *obj, moonbit_string_t key,
                                            void *value) {
  if (!obj || !value) return -2;
  int32_t len = Moonbit_array_length((void *)key);
  int32_t out_len = 0;
  int32_t invalid = 0;
  char *utf8 = mb_utf8_from_utf16(key, len, &out_len, &invalid);
  if (!utf8) {
    mb_orjson_build_err = invalid ? MB_ERR_INVALID_STR : MB_ERR_OOM;
    return invalid ? -1 : -2;
  }
  mb_orjson_node *k = mb_node_new(MB_ORJSON_STRING);
  if (!k) {
    free(utf8);
    mb_orjson_build_err = MB_ERR_OOM;
    return -2;
  }
  k->u.str.ptr = utf8;
  k->u.str.len = (size_t)out_len;
  if (!mb_obj_push((mb_orjson_node *)obj, k, (mb_orjson_node *)value)) {
    mb_node_free(k, 1);
    mb_orjson_build_err = MB_ERR_OOM;
    return -2;
  }
  return 0;
}

MOONBIT_EXPORT void mb_orjson_tree_free(void *tree) {
  mb_node_free((mb_orjson_node *)tree, 1);
}

/*============================================================================
 * Serialization
 *==========================================================================*/

typedef struct {
  char *ptr;
  size_t len;
  size_t cap;
  int32_t status; /* 0 = ok, 1 = out of memory, 2 = recursion limit */
} mb_sbuf;

static void mb_sbuf_init(mb_sbuf *b) {
  b->ptr = (char *)malloc(256);
  b->len = 0;
  b->cap = b->ptr ? 256 : 0;
  b->status = b->ptr ? 0 : 1;
}

static void mb_sbuf_reserve(mb_sbuf *b, size_t extra) {
  if (b->status) return;
  if (b->len + extra <= b->cap) return;
  size_t cap = b->cap ? b->cap : 64;
  while (cap < b->len + extra) cap *= 2;
  char *p = (char *)realloc(b->ptr, cap);
  if (!p) {
    b->status = 1;
    return;
  }
  b->ptr = p;
  b->cap = cap;
}

static void mb_sbuf_putc(mb_sbuf *b, char c) {
  mb_sbuf_reserve(b, 1);
  if (b->status) return;
  b->ptr[b->len++] = c;
}

static void mb_sbuf_puts(mb_sbuf *b, const char *s) {
  size_t len = strlen(s);
  mb_sbuf_reserve(b, len);
  if (b->status) return;
  memcpy(b->ptr + b->len, s, len);
  b->len += len;
}

static void mb_sbuf_put(mb_sbuf *b, const char *s, size_t len) {
  mb_sbuf_reserve(b, len);
  if (b->status) return;
  memcpy(b->ptr + b->len, s, len);
  b->len += len;
}

static void mb_sbuf_indent(mb_sbuf *b, int32_t level, int32_t indent) {
  size_t total = (size_t)level * (size_t)indent;
  mb_sbuf_reserve(b, total);
  if (b->status) return;
  memset(b->ptr + b->len, ' ', total);
  b->len += total;
}

/* orjson-compatible string escaping: short escapes for \b \f \n \r \t,
 * \u00xx (lowercase) for other control characters, everything else raw. */
static void mb_write_escaped_string(mb_sbuf *b, const char *s, size_t len) {
  mb_sbuf_putc(b, '"');
  for (size_t i = 0; i < len; i++) {
    unsigned char c = (unsigned char)s[i];
    switch (c) {
      case '"':
        mb_sbuf_puts(b, "\\\"");
        break;
      case '\\':
        mb_sbuf_puts(b, "\\\\");
        break;
      case '\b':
        mb_sbuf_puts(b, "\\b");
        break;
      case '\f':
        mb_sbuf_puts(b, "\\f");
        break;
      case '\n':
        mb_sbuf_puts(b, "\\n");
        break;
      case '\r':
        mb_sbuf_puts(b, "\\r");
        break;
      case '\t':
        mb_sbuf_puts(b, "\\t");
        break;
      default:
        if (c < 0x20) {
          char tmp[8];
          snprintf(tmp, sizeof(tmp), "\\u%04x", (unsigned)c);
          mb_sbuf_puts(b, tmp);
        } else {
          mb_sbuf_putc(b, (char)c);
        }
        break;
    }
  }
  mb_sbuf_putc(b, '"');
}

static size_t mb_reformat_double(const char *s, char *out) {
  const char *p = s;
  int32_t neg = (*p == '-');
  if (neg) p++;

  const char *e = strchr(p, 'e');
  int32_t exp10 = e ? (int32_t)strtol(e + 1, NULL, 10) : 0;
  const char *mend = e ? e : p + strlen(p);
  const char *dot = strchr(p, '.');
  int32_t int_digits =
      dot && dot < mend ? (int32_t)(dot - p) : (int32_t)(mend - p);

  char raw[64];
  int32_t n = 0;
  for (const char *q = p; q < mend && n < (int32_t)sizeof(raw) - 1; q++) {
    if (*q != '.') raw[n++] = *q;
  }

  int32_t fs = -1;
  for (int32_t i = 0; i < n; i++) {
    if (raw[i] != '0') {
      fs = i;
      break;
    }
  }
  char *o = out;
  if (fs < 0) {
    /* zero: yyjson prints "0.0" */
    if (neg) *o++ = '-';
    *o++ = '0';
    *o++ = '.';
    *o++ = '0';
    return (size_t)(o - out);
  }
  int32_t nd = 0;
  for (int32_t i = fs; i < n; i++) nd++;
  while (nd > 1 && raw[fs + nd - 1] == '0') nd--;
  int32_t E = exp10 + int_digits - fs - 1;

  if (neg) *o++ = '-';
  if (E >= 16 || E <= -6) {
    *o++ = raw[fs];
    if (nd > 1) {
      *o++ = '.';
      memcpy(o, raw + fs + 1, (size_t)(nd - 1));
      o += nd - 1;
    }
    *o++ = 'e';
    int32_t ae = E;
    if (E >= 0) {
      *o++ = '+';
    } else {
      *o++ = '-';
      ae = -E;
    }
    o += sprintf(o, "%d", (int)ae);
  } else if (E >= 0) {
    int32_t ip = E + 1;
    if (nd > ip) {
      memcpy(o, raw + fs, (size_t)ip);
      o += ip;
      *o++ = '.';
      memcpy(o, raw + fs + ip, (size_t)(nd - ip));
      o += nd - ip;
    } else {
      memcpy(o, raw + fs, (size_t)nd);
      o += nd;
      memset(o, '0', (size_t)(ip - nd));
      o += ip - nd;
      *o++ = '.';
      *o++ = '0';
    }
  } else {
    *o++ = '0';
    *o++ = '.';
    memset(o, '0', (size_t)(-E - 1));
    o += -E - 1;
    memcpy(o, raw + fs, (size_t)nd);
    o += nd;
  }
  return (size_t)(o - out);
}

/* Format a double the way orjson/zmij does. NaN and infinities serialize as
 * `null` (matching orjson). */
static void mb_write_double(mb_sbuf *b, double v) {
  if (isnan(v) || isinf(v)) {
    mb_sbuf_puts(b, "null");
    return;
  }
  char tmp[64];
  yyjson_val val;
  val.tag = YYJSON_TYPE_NUM | YYJSON_SUBTYPE_REAL;
  val.uni.f64 = v;
  char buf[64];
  yyjson_write_number(&val, buf);
  size_t len = mb_reformat_double(buf, tmp);
  mb_sbuf_put(b, tmp, len);
}

static void mb_ser_value(mb_sbuf *b, mb_orjson_node *n, int32_t level,
                         int32_t indent, int32_t sort_keys);

typedef struct {
  mb_orjson_node *key;
  mb_orjson_node *val;
} mb_kv;

static int mb_kv_cmp(const void *a, const void *b) {
  const mb_kv *ka = (const mb_kv *)a;
  const mb_kv *kb = (const mb_kv *)b;
  size_t min = ka->key->u.str.len < kb->key->u.str.len ? ka->key->u.str.len
                                                      : kb->key->u.str.len;
  int c = memcmp(ka->key->u.str.ptr, kb->key->u.str.ptr, min);
  if (c) return c;
  if (ka->key->u.str.len == kb->key->u.str.len) return 0;
  return ka->key->u.str.len < kb->key->u.str.len ? -1 : 1;
}

static void mb_ser_array(mb_sbuf *b, mb_orjson_node *n, int32_t level,
                         int32_t indent, int32_t sort_keys) {
  if (b->status) return;
  if (level >= 254) {
    b->status = 2;
    return;
  }
  size_t cnt = n->u.arr.len;
  if (cnt == 0) {
    mb_sbuf_puts(b, "[]");
    return;
  }
  mb_sbuf_putc(b, '[');
  for (size_t i = 0; i < cnt; i++) {
    if (i) mb_sbuf_putc(b, ',');
    if (indent > 0) {
      mb_sbuf_putc(b, '\n');
      mb_sbuf_indent(b, level + 1, indent);
    }
    mb_ser_value(b, n->u.arr.items[i], level + 1, indent, sort_keys);
    if (b->status) return;
  }
  if (indent > 0) {
    mb_sbuf_putc(b, '\n');
    mb_sbuf_indent(b, level, indent);
  }
  mb_sbuf_putc(b, ']');
}

static void mb_ser_object(mb_sbuf *b, mb_orjson_node *n, int32_t level,
                          int32_t indent, int32_t sort_keys) {
  if (b->status) return;
  if (level >= 254) {
    b->status = 2;
    return;
  }
  size_t cnt = n->u.obj.len;
  if (cnt == 0) {
    mb_sbuf_puts(b, "{}");
    return;
  }
  mb_kv *kvs = NULL;
  if (sort_keys) {
    kvs = (mb_kv *)malloc(cnt * sizeof(mb_kv));
    if (!kvs) {
      b->status = 1;
      return;
    }
    for (size_t i = 0; i < cnt; i++) {
      kvs[i].key = n->u.obj.keys[i];
      kvs[i].val = n->u.obj.vals[i];
    }
    qsort(kvs, cnt, sizeof(mb_kv), mb_kv_cmp);
  }
  mb_sbuf_putc(b, '{');
  for (size_t i = 0; i < cnt; i++) {
    mb_orjson_node *key = sort_keys ? kvs[i].key : n->u.obj.keys[i];
    mb_orjson_node *val = sort_keys ? kvs[i].val : n->u.obj.vals[i];
    if (i) mb_sbuf_putc(b, ',');
    if (indent > 0) {
      mb_sbuf_putc(b, '\n');
      mb_sbuf_indent(b, level + 1, indent);
    }
    mb_write_escaped_string(b, key->u.str.ptr, key->u.str.len);
    mb_sbuf_putc(b, ':');
    if (indent > 0) mb_sbuf_putc(b, ' ');
    mb_ser_value(b, val, level + 1, indent, sort_keys);
    if (b->status) break;
  }
  free(kvs);
  if (b->status) return;
  if (indent > 0) {
    mb_sbuf_putc(b, '\n');
    mb_sbuf_indent(b, level, indent);
  }
  mb_sbuf_putc(b, '}');
}

static void mb_ser_value(mb_sbuf *b, mb_orjson_node *n, int32_t level,
                         int32_t indent, int32_t sort_keys) {
  if (b->status) return;
  switch (n->type) {
    case MB_ORJSON_NULL:
      mb_sbuf_puts(b, "null");
      break;
    case MB_ORJSON_BOOL:
      mb_sbuf_puts(b, n->u.boolean ? "true" : "false");
      break;
    case MB_ORJSON_INT: {
      char tmp[32];
      int len = snprintf(tmp, sizeof(tmp), "%lld", (long long)n->u.i64);
      mb_sbuf_put(b, tmp, (size_t)len);
      break;
    }
    case MB_ORJSON_UINT: {
      char tmp[32];
      int len = snprintf(tmp, sizeof(tmp), "%llu", (unsigned long long)n->u.u64);
      mb_sbuf_put(b, tmp, (size_t)len);
      break;
    }
    case MB_ORJSON_FLOAT:
      mb_write_double(b, n->u.f64);
      break;
    case MB_ORJSON_STRING:
      mb_write_escaped_string(b, n->u.str.ptr, n->u.str.len);
      break;
    case MB_ORJSON_RAW:
      mb_sbuf_put(b, n->u.str.ptr, n->u.str.len);
      break;
    case MB_ORJSON_ARRAY:
      mb_ser_array(b, n, level, indent, sort_keys);
      break;
    case MB_ORJSON_OBJECT:
      mb_ser_object(b, n, level, indent, sort_keys);
      break;
    default:
      b->status = 1;
      break;
  }
}

typedef struct {
  int32_t ok;
  int32_t _pad;
  char *text;
  size_t len;
  char *err;
} mb_orjson_dump_result;

MOONBIT_EXPORT void *mb_orjson_dump(void *tree, int64_t indent,
                                    int64_t sort_keys, int64_t append_newline) {
  mb_orjson_node *root = (mb_orjson_node *)tree;
  mb_orjson_dump_result *res =
      (mb_orjson_dump_result *)calloc(1, sizeof(*res));
  if (!res) return NULL;
  mb_sbuf b;
  mb_sbuf_init(&b);
  if (indent < 0) indent = 0;
  mb_ser_value(&b, root, 0, (int32_t)indent, sort_keys ? 1 : 0);
  if (b.status == 0 && append_newline) mb_sbuf_putc(&b, '\n');
  if (b.status != 0) {
    res->ok = 0;
    res->err = mb_strdup(b.status == 2 ? MB_ERR_RECURSION : MB_ERR_OOM);
    free(b.ptr);
    return res;
  }
  mb_sbuf_reserve(&b, 1);
  if (b.status != 0) {
    res->ok = 0;
    res->err = mb_strdup(MB_ERR_OOM);
    free(b.ptr);
    return res;
  }
  b.ptr[b.len] = '\0';
  res->ok = 1;
  res->text = b.ptr;
  res->len = b.len;
  return res;
}

MOONBIT_EXPORT int64_t mb_orjson_dump_ok(void *handle) {
  return ((mb_orjson_dump_result *)handle)->ok ? 1 : 0;
}

MOONBIT_EXPORT moonbit_string_t mb_orjson_dump_text(void *handle) {
  mb_orjson_dump_result *res = (mb_orjson_dump_result *)handle;
  return mb_mb_string_from_utf8(res->text, res->len);
}

MOONBIT_EXPORT moonbit_string_t mb_orjson_dump_error(void *handle) {
  mb_orjson_dump_result *res = (mb_orjson_dump_result *)handle;
  const char *msg = res->err ? res->err : MB_ERR_OOM;
  return mb_mb_string_from_utf8(msg, strlen(msg));
}

MOONBIT_EXPORT void mb_orjson_dump_free(void *handle) {
  mb_orjson_dump_result *res = (mb_orjson_dump_result *)handle;
  if (!res) return;
  free(res->text);
  free(res->err);
  free(res);
}
