// MoonBit bindings for orjson's JSON engine (the yyjson fork vendored by
// orjson), exposing orjson-compatible parsing and serialization semantics.
//
// Mirrors `orjson.loads` / `orjson.dumps`:
// - parsing accepts only strict RFC 8259 JSON (no comments, trailing commas,
//   NaN/Infinity literals, ...), like orjson
// - non-negative integers decode as `UInt`, negative integers as `Int`,
//   numbers outside the 64-bit integer ranges decode as `Float`
// - serialization escapes strings and formats doubles exactly like orjson
// - `stringify_with(indent=2)` matches `orjson.OPT_INDENT_2`, `sort_keys`
//   matches `OPT_SORT_KEYS` and `append_newline` matches `OPT_APPEND_NEWLINE`

///|
/// A JSON value.
pub(all) enum Json {
  /// `null`.
  Null
  /// `true` or `false`.
  Bool(Bool)
  /// A signed 64-bit integer (always negative when produced by `parse`).
  Int(Int64)
  /// An unsigned 64-bit integer (non-negative values from `parse`).
  UInt(UInt64)
  /// A double-precision floating point number.
  Float(Double)
  /// A string.
  String(String)
  /// An array.
  Array(Array[Json])
  /// An object.
  Object(Map[String, Json])
  /// A pre-encoded JSON fragment emitted verbatim, like `orjson.Fragment`.
  ///
  /// The content is not checked or parsed at all: dumping `Raw("{invalid")`
  /// yields `{invalid`.
  Raw(String)
}

///|
/// Errors raised by this package.
pub(all) suberror JsonError {
  /// The input is not valid JSON. The first field is an orjson-compatible
  /// error message (including the `line`/`column`/`char` suffix), the second
  /// field is the 0-based character position of the error.
  DecodeError(String, Int32)
  /// The value cannot be serialized (e.g. a string containing a lone
  /// surrogate, or nesting deeper than 254 levels).
  EncodeError(String)
}

///|
/// Parse a JSON document from a `String` (mirrors `orjson.loads`).
///
/// The input must be valid UTF-8 once encoded; strings containing lone
/// surrogates are rejected.
pub fn parse(input : String) -> Json raise JsonError {
  let handle = parse_string_ffi(input)
  decode(handle)
}

///|
/// Parse a JSON document from UTF-8 `Bytes` (mirrors `orjson.loads`).
///
/// Invalid UTF-8 input is rejected.
pub fn parse_bytes(input : Bytes) -> Json raise JsonError {
  let handle = parse_bytes_ffi(input)
  decode(handle)
}

///|
fn decode(handle : ParseHandle) -> Json raise JsonError {
  if parse_handle_is_null(handle) != 0 {
    raise JsonError::EncodeError("failed to allocate memory")
  }
  if parse_handle_ok(handle) == 0 {
    let message = parse_handle_error(handle)
    let position = parse_handle_error_pos(handle)
    parse_handle_free(handle)
    raise JsonError::DecodeError(message, position)
  }
  let json = convert(parse_handle_root(handle))
  parse_handle_free(handle)
  json
}

///|
fn convert(node : Node) -> Json {
  match node_type(node) {
    0 => Json::Null
    1 => Json::Bool(node_bool(node) != 0)
    2 => Json::Int(node_int(node))
    3 => Json::UInt(node_uint(node))
    4 => Json::Float(node_float(node))
    5 => Json::String(node_string(node))
    7 => {
      let size = node_size(node)
      let items : Array[Json] = []
      for i = 0; i < size; i = i + 1 {
        items.push(convert(node_array_get(node, i)))
      }
      Json::Array(items)
    }
    8 => {
      let size = node_size(node)
      let map : Map[String, Json] = Map([])
      for i = 0; i < size; i = i + 1 {
        map.set(node_object_key(node, i), convert(node_object_get(node, i)))
      }
      Json::Object(map)
    }
    _ => Json::Null
  }
}

///|
/// Maximum nesting depth of containers accepted by `stringify`, matching
/// orjson's "Recursion limit reached" limit.
const MAX_DEPTH : Int32 = 254

///|
/// Serialize `value` to compact JSON (mirrors `orjson.dumps`).
pub fn stringify(value : Json) -> String raise JsonError {
  stringify_with(value)
}

///|
/// Serialize `value` to JSON with options.
///
/// Parameters:
///
/// - `indent`: spaces per nesting level; `2` matches `orjson.OPT_INDENT_2`.
///   `0` (default) produces compact output. Empty containers are always
///   written as `[]` / `{}`.
/// - `sort_keys`: sort object keys by code point, like `OPT_SORT_KEYS`.
/// - `append_newline`: append a trailing `\n`, like `OPT_APPEND_NEWLINE`.
pub fn stringify_with(
  value : Json,
  indent~ : Int32 = 0,
  sort_keys~ : Bool = false,
  append_newline~ : Bool = false,
) -> String raise JsonError {
  let tree = build(value, 0)
  let handle = dump_ffi(
    tree,
    indent,
    if sort_keys {
      1
    } else {
      0
    },
    if append_newline {
      1
    } else {
      0
    },
  )
  tree_free_ffi(tree)
  if dump_handle_is_null(handle) != 0 {
    raise JsonError::EncodeError("failed to allocate memory")
  }
  if dump_ok(handle) == 0 {
    let message = dump_error(handle)
    dump_free(handle)
    raise JsonError::EncodeError(message)
  }
  let text = dump_text(handle)
  dump_free(handle)
  text
}

///|
fn build(value : Json, depth : Int32) -> Node raise JsonError {
  match value {
    Json::Null => build_null_ffi()
    Json::Bool(b) => build_bool_ffi(if b { 1 } else { 0 })
    Json::Int(i) => build_int_ffi(i)
    Json::UInt(u) => build_uint_ffi(u)
    Json::Float(f) => build_float_ffi(f)
    Json::String(s) => build_string_checked(s)
    Json::Raw(s) => build_raw_checked(s)
    Json::Array(items) => {
      if depth >= MAX_DEPTH {
        raise JsonError::EncodeError("Recursion limit reached")
      }
      let node = build_array_ffi()
      if node_is_null(node) != 0 {
        raise JsonError::EncodeError("failed to allocate memory")
      }
      errdefer tree_free_ffi(node)
      for item in items {
        let child = build(item, depth + 1)
        if array_push_ffi(node, child) != 0 {
          tree_free_ffi(child)
          raise JsonError::EncodeError(build_error_ffi())
        }
      }
      node
    }
    Json::Object(map) => {
      if depth >= MAX_DEPTH {
        raise JsonError::EncodeError("Recursion limit reached")
      }
      let node = build_object_ffi()
      if node_is_null(node) != 0 {
        raise JsonError::EncodeError("failed to allocate memory")
      }
      errdefer tree_free_ffi(node)
      for key, value in map {
        let child = build(value, depth + 1)
        if object_put_ffi(node, key, child) != 0 {
          tree_free_ffi(child)
          raise JsonError::EncodeError(build_error_ffi())
        }
      }
      node
    }
  }
}

///|
fn build_string_checked(value : String) -> Node raise JsonError {
  let node = build_string_ffi(value)
  if node_is_null(node) != 0 {
    raise JsonError::EncodeError(build_error_ffi())
  }
  node
}

///|
fn build_raw_checked(value : String) -> Node raise JsonError {
  let node = build_raw_ffi(value)
  if node_is_null(node) != 0 {
    raise JsonError::EncodeError(build_error_ffi())
  }
  node
}
