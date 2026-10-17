// FFI declarations for the C bridge in `c/bridge.c`.
//
// `ParseHandle` and `DumpHandle` are raw malloc'd pointers that are explicitly
// recycled with the matching `*_free` functions; `Node` points into a tree
// owned by one of those handles.

///|
#external
priv type ParseHandle

///|
#external
priv type DumpHandle

///|
#external
priv type Node

///|
#borrow(input)
extern "C" fn parse_bytes_ffi(input : Bytes) -> ParseHandle = "mb_orjson_parse_bytes"

///|
#borrow(input)
extern "C" fn parse_string_ffi(input : String) -> ParseHandle = "mb_orjson_parse_string"

///|
extern "C" fn parse_handle_is_null(handle : ParseHandle) -> Int32 = "mb_orjson_handle_is_null"

///|
extern "C" fn parse_handle_ok(handle : ParseHandle) -> Int32 = "mb_orjson_parse_ok"

///|
extern "C" fn parse_handle_root(handle : ParseHandle) -> Node = "mb_orjson_parse_root"

///|
extern "C" fn parse_handle_error(handle : ParseHandle) -> String = "mb_orjson_parse_error"

///|
extern "C" fn parse_handle_error_pos(handle : ParseHandle) -> Int32 = "mb_orjson_parse_error_pos"

///|
extern "C" fn parse_handle_free(handle : ParseHandle) -> Unit = "mb_orjson_parse_free"

///|
extern "C" fn node_type(node : Node) -> Int32 = "mb_orjson_node_type"

///|
extern "C" fn node_bool(node : Node) -> Int32 = "mb_orjson_node_bool"

///|
extern "C" fn node_int(node : Node) -> Int64 = "mb_orjson_node_int"

///|
extern "C" fn node_uint(node : Node) -> UInt64 = "mb_orjson_node_uint"

///|
extern "C" fn node_float(node : Node) -> Double = "mb_orjson_node_float"

///|
extern "C" fn node_string(node : Node) -> String = "mb_orjson_node_string"

///|
extern "C" fn node_size(node : Node) -> Int32 = "mb_orjson_node_size"

///|
extern "C" fn node_array_get(node : Node, index : Int32) -> Node = "mb_orjson_node_array_get"

///|
extern "C" fn node_object_key(node : Node, index : Int32) -> String = "mb_orjson_node_object_key"

///|
extern "C" fn node_object_get(node : Node, index : Int32) -> Node = "mb_orjson_node_object_get"

///|
extern "C" fn node_is_null(node : Node) -> Int32 = "mb_orjson_node_is_null"

///|
extern "C" fn build_null_ffi() -> Node = "mb_orjson_build_null"

///|
extern "C" fn build_bool_ffi(value : Int32) -> Node = "mb_orjson_build_bool"

///|
extern "C" fn build_int_ffi(value : Int64) -> Node = "mb_orjson_build_int"

///|
extern "C" fn build_uint_ffi(value : UInt64) -> Node = "mb_orjson_build_uint"

///|
extern "C" fn build_float_ffi(value : Double) -> Node = "mb_orjson_build_float"

///|
#borrow(value)
extern "C" fn build_string_ffi(value : String) -> Node = "mb_orjson_build_string"

///|
#borrow(value)
extern "C" fn build_raw_ffi(value : String) -> Node = "mb_orjson_build_raw"

///|
extern "C" fn build_array_ffi() -> Node = "mb_orjson_build_array"

///|
extern "C" fn build_object_ffi() -> Node = "mb_orjson_build_object"

///|
extern "C" fn array_push_ffi(array : Node, item : Node) -> Int32 = "mb_orjson_array_push"

///|
#borrow(key)
extern "C" fn object_put_ffi(
  object : Node,
  key : String,
  value : Node,
) -> Int32 = "mb_orjson_object_put"

///|
extern "C" fn build_error_ffi() -> String = "mb_orjson_build_error"

///|
extern "C" fn tree_free_ffi(tree : Node) -> Unit = "mb_orjson_tree_free"

///|
extern "C" fn dump_ffi(
  tree : Node,
  indent : Int32,
  sort_keys : Int32,
  append_newline : Int32,
) -> DumpHandle = "mb_orjson_dump"

///|
extern "C" fn dump_handle_is_null(handle : DumpHandle) -> Int32 = "mb_orjson_handle_is_null"

///|
extern "C" fn dump_ok(handle : DumpHandle) -> Int32 = "mb_orjson_dump_ok"

///|
extern "C" fn dump_text(handle : DumpHandle) -> String = "mb_orjson_dump_text"

///|
extern "C" fn dump_error(handle : DumpHandle) -> String = "mb_orjson_dump_error"

///|
extern "C" fn dump_free(handle : DumpHandle) -> Unit = "mb_orjson_dump_free"
