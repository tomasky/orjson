// Blackbox tests. Expected outputs were generated with orjson 3.13.0 (which
// embeds the same yyjson fork) to verify byte-for-byte compatibility.

///|
fn parse_and_dump(input : String) -> String raise @orjson.JsonError {
  @orjson.stringify(@orjson.parse(input))
}

///|
fn decode_error(input : String) -> (String, Int32)? {
  try {
    ignore(@orjson.parse(input))
    None
  } catch {
    @orjson.JsonError::DecodeError(msg, pos) => Some((msg, pos))
    @orjson.JsonError::EncodeError(_) => None
  }
}

///|
fn check_decode_error(
  input : String,
  message : String,
  position : Int32,
) -> Unit raise {
  match decode_error(input) {
    Some((msg, pos)) => {
      assert_eq(msg, message)
      assert_eq(pos, position)
    }
    None => fail("expected a decode error for: " + input)
  }
}

///|
fn check_bytes_decode_error(
  input : Bytes,
  message : String,
  position : Int32,
) -> Unit raise {
  let result = try {
    ignore(@orjson.parse_bytes(input))
    None
  } catch {
    @orjson.JsonError::DecodeError(msg, pos) => Some((msg, pos))
    @orjson.JsonError::EncodeError(_) => None
  }
  match result {
    Some((msg, pos)) => {
      assert_eq(msg, message)
      assert_eq(pos, position)
    }
    None => fail("expected a decode error")
  }
}

///|
test "parse: scalar types" {
  match @orjson.parse("null") {
    @orjson.Json::Null => ()
    _ => fail("null")
  }
  match @orjson.parse("true") {
    @orjson.Json::Bool(true) => ()
    _ => fail("true")
  }
  match @orjson.parse("false") {
    @orjson.Json::Bool(false) => ()
    _ => fail("false")
  }
  match @orjson.parse("5") {
    @orjson.Json::UInt(v) => assert_eq(v, 5UL)
    _ => fail("5 should decode as UInt")
  }
  match @orjson.parse("-5") {
    @orjson.Json::Int(v) => assert_eq(v, -5L)
    _ => fail("-5 should decode as Int")
  }
  match @orjson.parse("18446744073709551615") {
    @orjson.Json::UInt(v) => assert_eq(v, 18446744073709551615UL)
    _ => fail("u64 max")
  }
  match @orjson.parse("-9223372036854775808") {
    @orjson.Json::Int(v) => assert_eq(v, -9223372036854775807L - 1L)
    _ => fail("i64 min")
  }
  match @orjson.parse("1.5") {
    @orjson.Json::Float(v) => assert_eq(v, 1.5)
    _ => fail("1.5")
  }
  match @orjson.parse("\"hi\"") {
    @orjson.Json::String(v) => assert_eq(v, "hi")
    _ => fail("string")
  }
}

///|
test "parse: integers beyond 64-bit become floats" {
  match @orjson.parse("9223372036854775808") {
    @orjson.Json::UInt(v) => assert_eq(v, 9223372036854775808UL)
    _ => fail("i64 max + 1 should decode as UInt")
  }
  assert_eq(parse_and_dump("18446744073709551616"), "1.8446744073709552e+19")
  assert_eq(parse_and_dump("-9223372036854775809"), "-9.223372036854776e+18")
  check_decode_error(
    "1e999", "number is infinity when parsed as double: line 1 column 1 (char 0)",
    0,
  )
}

///|
test "parse: escapes" {
  assert_eq(parse_and_dump("\"\\u0041\""), "\"A\"")
  assert_eq(parse_and_dump("\"\\/\\\\\\\"\""), "\"/\\\\\\\"\"")
  assert_eq(parse_and_dump("\"\\ud83d\\ude00\""), "\"😀\"")
  assert_eq(parse_and_dump("\"a\\u000bb\""), "\"a\\u000bb\"")
}

///|
test "parse: duplicates, last one wins" {
  assert_eq(parse_and_dump("{\"a\":1,\"a\":2}"), "{\"a\":2}")
}

///|
test "dump: float formatting matches orjson" {
  assert_eq(@orjson.stringify(@orjson.Json::Float(1.0)), "1.0")
  assert_eq(@orjson.stringify(@orjson.Json::Float(-1.5)), "-1.5")
  assert_eq(@orjson.stringify(@orjson.Json::Float(0.1)), "0.1")
  assert_eq(@orjson.stringify(@orjson.Json::Float(0.0001)), "0.0001")
  assert_eq(
    @orjson.stringify(@orjson.Json::Float(1000000000000000.0)),
    "1000000000000000.0",
  )
  assert_eq(@orjson.stringify(@orjson.Json::Float(1.0e16)), "1e+16")
  assert_eq(@orjson.stringify(@orjson.Json::Float(1.0e20)), "1e+20")
  assert_eq(@orjson.stringify(@orjson.Json::Float(0.00001)), "0.00001")
  assert_eq(@orjson.stringify(@orjson.Json::Float(1.0e-6)), "1e-6")
  assert_eq(
    @orjson.stringify(@orjson.Json::Float(123456789.123456789)),
    "123456789.12345679",
  )
  assert_eq(
    @orjson.stringify(@orjson.Json::Float(1234567890123456789012.0)),
    "1.2345678901234568e+21",
  )
  assert_eq(
    @orjson.stringify(
      @orjson.Json::Float(0x7FEFFFFFFFFFFFFFL.reinterpret_as_double()),
    ),
    "1.7976931348623157e+308",
  )
}

///|
test "dump: negative zero, nan and infinity" {
  match @orjson.parse("-0.0") {
    @orjson.Json::Float(v) =>
      assert_eq(@orjson.stringify(@orjson.Json::Float(v)), "-0.0")
    _ => fail("-0.0")
  }
  let nan = 0x7FF8000000000000L.reinterpret_as_double()
  let inf = 0x7FF0000000000000L.reinterpret_as_double()
  let neg_inf = 0xFFF0000000000000L.reinterpret_as_double()
  assert_eq(@orjson.stringify(@orjson.Json::Float(nan)), "null")
  assert_eq(@orjson.stringify(@orjson.Json::Float(inf)), "null")
  assert_eq(@orjson.stringify(@orjson.Json::Float(neg_inf)), "null")
}

///|
test "dump: string escaping matches orjson" {
  assert_eq(
    @orjson.stringify(@orjson.Json::String("a\"b\\c")),
    "\"a\\\"b\\\\c\"",
  )
  assert_eq(
    @orjson.stringify(@orjson.Json::String("\b\f\n\r\t")),
    "\"\\b\\f\\n\\r\\t\"",
  )
  assert_eq(
    @orjson.stringify(@orjson.Json::String("\u{0000}\u{0001}\u{001f}")),
    "\"\\u0000\\u0001\\u001f\"",
  )
  assert_eq(@orjson.stringify(@orjson.Json::String("\u{007f}")), "\"\u{007f}\"")
  assert_eq(
    @orjson.stringify(@orjson.Json::String("/\u{2028}")),
    "\"/\u{2028}\"",
  )
  assert_eq(@orjson.stringify(@orjson.Json::String("é😀")), "\"é😀\"")
}

///|
test "dump: compact, indent and sort" {
  let value : @orjson.Json = @orjson.Json::Object({
    "b": @orjson.Json::Array([
      @orjson.Json::UInt(1UL),
      @orjson.Json::UInt(2UL),
      @orjson.Json::Object({ "c": @orjson.Json::Array([]) }),
    ]),
    "d": @orjson.Json::Object(Map([])),
    "e": @orjson.Json::Array([@orjson.Json::Array([])]),
    "a": @orjson.Json::UInt(1UL),
  })
  assert_eq(
    @orjson.stringify_with(value, sort_keys=true),
    "{\"a\":1,\"b\":[1,2,{\"c\":[]}],\"d\":{},\"e\":[[]]}",
  )
  assert_eq(
    @orjson.stringify_with(value, indent=2, sort_keys=true),
    "{\n  \"a\": 1,\n  \"b\": [\n    1,\n    2,\n    {\n      \"c\": []\n    }\n  ],\n  \"d\": {},\n  \"e\": [\n    []\n  ]\n}",
  )
  assert_eq(
    @orjson.stringify_with(value, sort_keys=true, append_newline=true),
    "{\"a\":1,\"b\":[1,2,{\"c\":[]}],\"d\":{},\"e\":[[]]}\n",
  )
  assert_eq(
    @orjson.stringify_with(value, indent=2, sort_keys=true, append_newline=true),
    "{\n  \"a\": 1,\n  \"b\": [\n    1,\n    2,\n    {\n      \"c\": []\n    }\n  ],\n  \"d\": {},\n  \"e\": [\n    []\n  ]\n}\n",
  )
}

///|
test "dump: raw fragments are emitted verbatim" {
  assert_eq(@orjson.stringify(@orjson.Json::Raw("{invalid")), "{invalid")
  assert_eq(
    @orjson.stringify(
      @orjson.Json::Array([@orjson.Json::Raw("[1,2]"), @orjson.Json::Raw("3")]),
    ),
    "[[1,2],3]",
  )
}

///|
test "parse: decode errors match orjson" {
  check_decode_error(
    "", "Input is a zero-length, empty document: line 1 column 1 (char 0)", 0,
  )
  check_decode_error(" ", "input data is empty: line 1 column 1 (char 0)", 0)
  check_decode_error(
    "[1,]", "trailing comma is not allowed: line 1 column 3 (char 2)", 2,
  )
  check_decode_error(
    "{\n  \"a\": tru\n}", "invalid literal, expected 'true': line 2 column 8 (char 9)",
    9,
  )
  check_decode_error(
    "\"\\ud800\"", "no low surrogate in string: line 1 column 2 (char 1)", 1,
  )
  check_decode_error(
    "true false", "unexpected content after document: line 1 column 6 (char 5)",
    5,
  )
  check_decode_error(
    "\"a\u{0001}b\"", "unexpected control character in string: line 1 column 3 (char 2)",
    2,
  )
  check_decode_error(
    "[1, 2", "unexpected end of data: line 1 column 6 (char 5)", 5,
  )
  check_decode_error(
    "{\"a\" 1}", "unexpected character, expected ':' after key: line 1 column 6 (char 5)",
    5,
  )
  check_decode_error(
    "\"é\\q\"", "invalid escaped sequence in string: line 1 column 3 (char 2)",
    2,
  )
}

///|
test "parse_bytes: valid and invalid UTF-8" {
  assert_eq(
    @orjson.stringify(@orjson.parse_bytes(b"{\"a\":[1,2]}")),
    "{\"a\":[1,2]}",
  )
  check_bytes_decode_error(
    b"", "Input is a zero-length, empty document: line 1 column 1 (char 0)", 0,
  )
  check_bytes_decode_error(
    b"\xff", "str is not valid UTF-8: surrogates not allowed: line 1 column 1 (char 0)",
    0,
  )
  check_bytes_decode_error(
    b"{\"a\": 1} \xed\xa0\x80", "str is not valid UTF-8: surrogates not allowed: line 1 column 1 (char 0)",
    0,
  )
  check_bytes_decode_error(
    b"\xef\xbb\xbf{}", "UTF-8 byte order mark (BOM) is not supported: line 1 column 1 (char 0)",
    0,
  )
}

///|
test "parse: lone surrogate in a MoonBit string" {
  let lone_surrogate = "😀".unsafe_substring(start=0, end=1)
  check_decode_error(
    lone_surrogate, "str is not valid UTF-8: surrogates not allowed: line 1 column 1 (char 0)",
    0,
  )
}

///|
test "dump: lone surrogate is rejected" {
  let lone_surrogate = "😀".unsafe_substring(start=0, end=1)
  let result = try {
    ignore(@orjson.stringify(@orjson.Json::String(lone_surrogate)))
    None
  } catch {
    @orjson.JsonError::EncodeError(msg) => Some(msg)
    @orjson.JsonError::DecodeError(msg, _) =>
      fail("unexpected decode error: " + msg)
  }
  match result {
    Some(msg) =>
      assert_eq(msg, "str is not valid UTF-8: surrogates not allowed")
    None => fail("expected an encode error")
  }
}

///|
test "parse: depth limits match yyjson/orjson" {
  let deep_1024 = "[".repeat(1024) + "]".repeat(1024)
  ignore(@orjson.parse(deep_1024))
  let deep_1025 = "[".repeat(1025) + "]".repeat(1025)
  check_decode_error(
    deep_1025, "depth limit exceeded: line 1 column 1026 (char 1025)", 1025,
  )
}

///|
test "dump: recursion limit matches orjson" {
  let mut value : @orjson.Json = @orjson.Json::Null
  for i = 0; i < 254; i = i + 1 {
    value = @orjson.Json::Array([value])
  }
  ignore(@orjson.stringify(value))
  let too_deep = @orjson.Json::Array([value])
  let result = try {
    ignore(@orjson.stringify(too_deep))
    None
  } catch {
    @orjson.JsonError::EncodeError(msg) => Some(msg)
    @orjson.JsonError::DecodeError(msg, _) =>
      fail("unexpected decode error: " + msg)
  }
  match result {
    Some(msg) => assert_eq(msg, "Recursion limit reached")
    None => fail("expected a recursion limit error")
  }
}

///|
test "round trips preserve values" {
  let inputs = [
    "null", "true", "[1,2.5,-3,\"x\",null,{},[]]", "{\"nested\":{\"a\":[1,{\"b\":2}]},\"s\":\"\\u00e9\\n\"}",
    "18446744073709551615", "-9223372036854775808", "0.1", "2.2250738585072014e-308",
  ]
  for input in inputs {
    let value = @orjson.parse(input)
    let dumped = @orjson.stringify_with(value, sort_keys=true)
    assert_eq(
      @orjson.stringify_with(@orjson.parse(dumped), sort_keys=true),
      dumped,
    )
  }
}
