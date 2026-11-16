///|
test "asan stress: error and partial paths" {
  // decode errors free the handle; these must not leak or double-free
  let bad = [
    "",
    " ",
    "[1,]",
    "{",
    "tru",
    "\"\\ud800\"",
    "1e999",
    "{\"a\":1",
    "[1,2",
    "\"é\\q\"",
    "\u{0001}",
    "[".repeat(1000),
    "\"unterminated",
  ]
  for i = 0; i < 300; i = i + 1 {
    for s in bad {
      ignore(parse(s)) catch {
        _ => ()
      }
    }
  }
  // encode errors: recursion limit and lone surrogate free the whole tree
  for i = 0; i < 300; i = i + 1 {
    let mut deep : Json = Json::Null
    for j = 0; j < 300; j = j + 1 {
      deep = Json::Array([deep])
    }
    ignore(stringify(deep)) catch {
      _ => ()
    }
    let lone = "😀".unsafe_substring(start=0, end=1)
    ignore(stringify(Json::String(lone))) catch {
      _ => ()
    }
  }
  // round-trip churn over nested documents
  let doc = "{\"a\":[1,2.5,true,null,{\"b\":\"é😀\"}],\"c\":{},\"d\":[],\"e\":-0.0}"
  for i = 0; i < 2000; i = i + 1 {
    let v = parse(doc)
    ignore(stringify(v))
    ignore(stringify_with(v, indent=2, sort_keys=true, append_newline=true))
    ignore(parse_bytes(b"{\"x\":[1,2,3],\"y\":\"z\"}"))
  }
}
