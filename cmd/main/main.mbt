///|
/// Entry point for the CLI or runnable program in this template.
/// Keep main focused; move logic into the library package.
/// Run with `moon run cmd/main` from the project root.
fn main {
  try {
    let document = @orjson.parse(
      "{\"name\":\"MoonBit\",\"stars\":1234,\"ratio\":0.75,\"ok\":true,\"tags\":[\"json\",null]}",
    )
    println(@orjson.stringify(document))
    println(@orjson.stringify_with(document, indent=2, sort_keys=true))
    let value : @orjson.Json = @orjson.Json::Object({
      "answer": @orjson.Json::UInt(42UL),
      "pi": @orjson.Json::Float(3.14159),
      "fragment": @orjson.Json::Raw("[1,2,3]"),
    })
    println(@orjson.stringify_with(value, sort_keys=true, append_newline=true))
    let _ = @orjson.parse("{not json")
  } catch {
    @orjson.JsonError::DecodeError(message, position) =>
      println("decode error at \{position}: \{message}")
    @orjson.JsonError::EncodeError(message) =>
      println("encode error: \{message}")
  }
}
