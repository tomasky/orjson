/* Shared yyjson build configuration.
 *
 * Every translation unit that includes yyjson must use the same defines, so
 * they live in this single header (included by both yyjson_impl.c and
 * bridge.c before including yyjson.h).
 *
 * orjson builds yyjson with:
 *   YYJSON_DISABLE_INCR_READER=1
 *   YYJSON_DISABLE_NON_STANDARD=1
 *   YYJSON_DISABLE_UTF8_VALIDATION=1
 *   YYJSON_DISABLE_UTILS=1
 *   YYJSON_DISABLE_WRITER=1
 *   YYJSON_READER_DEPTH_LIMIT=1024
 *
 * We keep UTF-8 validation (orjson validates with simdutf8 instead), and we
 * keep yyjson's writer and utilities because `yyjson_write_number()` (used for
 * shortest round-trip float formatting) lives in the utilities section.
 */
#ifndef ORJSON_YYJSON_CONF_H
#define ORJSON_YYJSON_CONF_H

#define YYJSON_DISABLE_INCR_READER 1
#define YYJSON_DISABLE_NON_STANDARD 1
#define YYJSON_READER_DEPTH_LIMIT 1024

#endif /* ORJSON_YYJSON_CONF_H */
