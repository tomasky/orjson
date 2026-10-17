# username/orjson

MoonBit bindings for [yyjson](https://github.com/ibireme/yyjson), the C JSON
engine vendored by [orjson](https://github.com/ijl/orjson). Parsing and
serialization follow orjson's behavior, so this package can be a drop-in
orjson-equivalent for MoonBit code.

This is a native-only package (the binding compiles the vendored C sources
through `native-stub`), tested on the `native` target.

## Usage

```mbt check
///|
test {
  let json = @orjson.parse("{\"a\": [1, 2.5, true, null]}")
  let text = @orjson.stringify(json)
  assert_eq(text, "{\"a\":[1,2.5,true,null]}")

  // indented output with sorted keys (like OPT_INDENT_2 | OPT_SORT_KEYS)
  let pretty = @orjson.stringify_with(json, indent=2, sort_keys=true)
  assert_eq(
    pretty, "{\n  \"a\": [\n    1,\n    2.5,\n    true,\n    null\n  ]\n}",
  )
}
```

## API

- `parse(String) -> Json raise JsonError` — parse a JSON document
  (mirrors `orjson.loads(str)`). Strings containing lone surrogates are
  rejected.
- `parse_bytes(Bytes) -> Json raise JsonError` — parse UTF-8 bytes
  (mirrors `orjson.loads(bytes)`). Invalid UTF-8 is rejected.
- `stringify(Json) -> String raise JsonError` — compact output
  (mirrors `orjson.dumps`).
- `stringify_with(Json, indent~, sort_keys~, append_newline~) -> String raise JsonError`
  — `indent=2` matches `orjson.OPT_INDENT_2`, `sort_keys=true` matches
  `orjson.OPT_SORT_KEYS`, `append_newline=true` matches
  `orjson.OPT_APPEND_NEWLINE`.

`Json` has the constructors `Null`, `Bool`, `Int(Int64)`, `UInt(UInt64)`,
`Float(Double)`, `String`, `Array`, `Object`, and `Raw` (like
`orjson.Fragment`, emitted verbatim without validation).

## orjson compatibility

- Strict RFC 8259 parsing: comments, trailing commas, `NaN`/`Infinity`
  literals and other non-standard extensions are rejected.
- Non-negative integers decode as `UInt`, negative integers as `Int`, and
  numbers outside the 64-bit integer ranges decode as `Float`.
- Strings are escaped exactly like orjson (`\b`, `\f`, `\n`, `\r`, `\t`,
  lowercase `\u00xx` for other control characters, raw UTF-8 elsewhere).
- Doubles use orjson's shortest-round-trip formatting: scientific notation
  when the decimal exponent is `>= 16` or `<= -6`, with an explicit sign
  (`1e+16`, `1e-6`) and a `.0` suffix for integral values (`1.0`).
  `NaN` and infinities serialize as `null`.
- Decode errors carry orjson's message format
  `{message}: line {line} column {column} (char {pos})` and the 0-based
  character position.
- Nesting limits match orjson: parse depth 1024, serialize depth 254
  (`Recursion limit reached`).
- Duplicate object keys keep the last value; `Raw` fragments are never
  validated.

## Differences from orjson

- Object dumping follows MoonBit `Map` iteration order unless
  `sort_keys=true` (orjson preserves dict insertion order).
- `int`/`float` are separated into `Int`/`UInt`/`Float` constructors
  (`orjson` uses Python's arbitrary-precision `int`).
- The package is native-only.

## Layout

- `orjson.mbt` — public API.
- `ffi.mbt` — extern declarations of the C bridge.
- `orjson_test.mbt` — hand-written unit tests.
- `orjson_diff_test.mbt`, `orjson_err_diff_test.mbt` — generated differential
  tests that compare outputs and decode errors byte-for-byte against orjson
  3.13.0.
- `c/bridge.c` — the C bridge (tree, parser, accessors, serializer).
- `c/yyjson_impl.c`, `c/yyjson_conf.h` — compile the vendored yyjson with
  orjson-compatible settings.
- `vendor/yyjson/` — yyjson as vendored and modified by orjson (MIT; see
  `vendor/README.md` and the license files under `vendor/`).
