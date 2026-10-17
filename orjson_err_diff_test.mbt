// AUTO-GENERATED error differential test vs orjson 3.13.0. Do not edit.

///|
fn err_cases() -> Array[(Bytes, String, Int32)] {
  [
    (
      b"{\"A\": [1\" 2.5, true,z null], \"b\": {,c\": \"x\\ny\"}}", "unexpected character, expected ',' or ']': line 1 column 9 (char 8)",
      8,
    ),
    (
      b"{\"a\": [1, 2.5, etrue, null", "unexpected character, expected a JSON value: line 1 column 16 (char 15)",
      15,
    ),
    (
      b".\"a\": [1, 2{5, true, null], \"b\": {\"\":y \"x\\ny\"}}", "no digit after sign: line 1 column 1 (char 0)",
      0,
    ),
    (b"{\"a\": [1", "unexpected end of data: line 1 column 9 (char 8)", 8),
    (
      b"{\"a\": [1, 2.5, true, nu", "unexpected end of data: line 1 column 24 (char 23)",
      23,
    ),
    (b"{\"a\":", "unexpected end of data: line 1 column 6 (char 5)", 5),
    (
      b"{\"a\"x [1, 2.5, true, null], \"b\": {\"c\": \":\\ny\"}}", "unexpected character, expected ':' after key: line 1 column 5 (char 4)",
      4,
    ),
    (
      b"{\"a\": [1, 2.5,,true, null]  \"b\": {\"c\": \"x\\ny\"}}", "unexpected character, expected a JSON value: line 1 column 15 (char 14)",
      14,
    ),
    (
      b"{a\": [1, 2.5, true, null], \"b\": {\"c\": \"x\\ny\"}}", "unexpected character, expected a string key: line 1 column 2 (char 1)",
      1,
    ),
    (
      b"{1a\": [\", 2.5, true, null], \"b\": {\"c: \"x\\ny\"}}", "unexpected character, expected a string key: line 1 column 2 (char 1)",
      1,
    ),
    (
      b"{\"a\": [1, 2.5, true, null], \"b\": {\"c\": \"x\\ny\"}}a", "unexpected content after document: line 1 column 48 (char 47)",
      47,
    ),
    (b"{\"a\": [1,", "unexpected end of data: line 1 column 10 (char 9)", 9),
    (
      b"{\"a\": [\\1, 2.5, true, null], \"b\": {\"c\": \"x\\ny\"}}", "unexpected character, expected a JSON value: line 1 column 8 (char 7)",
      7,
    ),
    (
      b"{\"a\": [1, 2.5, t\"ue, null], \"br :{\"c\": \"x\\ny\"}}", "invalid literal, expected 'true': line 1 column 16 (char 15)",
      15,
    ),
    (
      b"{\"a\"5 [1, 2.:, tr", "unexpected character, expected ':' after key: line 1 column 5 (char 4)",
      4,
    ),
    (b"", "Input is a zero-length, empty document: line 1 column 1 (char 0)", 0),
    (
      b"{\"a\": [1, 2.5, true, Null], \"b\":n {\"c\": \"x\\ny\"}}", "unexpected character, expected a JSON value: line 1 column 22 (char 21)",
      21,
    ),
    (
      b"{\"a\": [1, 2.5, True, null], \"b\": {\"c\": \"x\\ny\"}}", "unexpected character, expected a JSON value: line 1 column 16 (char 15)",
      15,
    ),
    (
      b"{\"a\"t: [,, 2.5, true, null]1 \"b\": {\"c\": \"x\\y\"}}", "unexpected character, expected ':' after key: line 1 column 5 (char 4)",
      4,
    ),
    (
      b"1, 2, 3]", "unexpected content after document: line 1 column 2 (char 1)",
      1,
    ),
    (
      b"c1, 2, 3]", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (
      b"[1 2, ]3", "unexpected character, expected ',' or ']': line 1 column 4 (char 3)",
      3,
    ),
    (b"[1,32,", "unexpected end of data: line 1 column 7 (char 6)", 6),
    (
      b" 1,[2, 3]", "unexpected content after document: line 1 column 3 (char 2)",
      2,
    ),
    (b"[1, ", "unexpected end of data: line 1 column 5 (char 4)", 4),
    (b"[1,32,  ]", "trailing comma is not allowed: line 1 column 6 (char 5)", 5),
    (
      b"[ ,s12, 3]", "unexpected character, expected a JSON value: line 1 column 3 (char 2)",
      2,
    ),
    (b"[1,", "unexpected end of data: line 1 column 4 (char 3)", 3),
    (
      b"[],13, 2 ", "unexpected content after document: line 1 column 3 (char 2)",
      2,
    ),
    (
      b"31, 2,[]", "unexpected content after document: line 1 column 3 (char 2)",
      2,
    ),
    (b"", "Input is a zero-length, empty document: line 1 column 1 (char 0)", 0),
    (
      b"[}1", "unexpected character, expected a JSON value: line 1 column 2 (char 1)",
      1,
    ),
    (b"[1, ", "unexpected end of data: line 1 column 5 (char 4)", 4),
    (b"[1,", "unexpected end of data: line 1 column 4 (char 3)", 3),
    (
      b"o[1, 2, 3]", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (b"", "Input is a zero-length, empty document: line 1 column 1 (char 0)", 0),
    (
      b",1, o2[ 3]", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (
      b",", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (
      b"/tuRe", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (b"tr", "unexpected end of data: line 1 column 3 (char 2)", 2),
    (b"", "Input is a zero-length, empty document: line 1 column 1 (char 0)", 0),
    (b"", "Input is a zero-length, empty document: line 1 column 1 (char 0)", 0),
    (b"tru", "unexpected end of data: line 1 column 4 (char 3)", 3),
    (
      b"ruE", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (b"tRe", "invalid literal, expected 'true': line 1 column 1 (char 0)", 0),
    (
      b"uret", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (
      b"T", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (b"", "Input is a zero-length, empty document: line 1 column 1 (char 0)", 0),
    (b"tuer", "invalid literal, expected 'true': line 1 column 1 (char 0)", 0),
    (
      b"T", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (b"truve", "invalid literal, expected 'true': line 1 column 1 (char 0)", 0),
    (b"tr]ue", "invalid literal, expected 'true': line 1 column 1 (char 0)", 0),
    (b"t[beur", "invalid literal, expected 'true': line 1 column 1 (char 0)", 0),
    (
      b"ret", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (b"", "Input is a zero-length, empty document: line 1 column 1 (char 0)", 0),
    (b"treu", "invalid literal, expected 'true': line 1 column 1 (char 0)", 0),
    (b"", "Input is a zero-length, empty document: line 1 column 1 (char 0)", 0),
    (b"", "Input is a zero-length, empty document: line 1 column 1 (char 0)", 0),
    (b"nll", "invalid literal, expected 'null': line 1 column 1 (char 0)", 0),
    (b"n6ull", "invalid literal, expected 'null': line 1 column 1 (char 0)", 0),
    (b"", "Input is a zero-length, empty document: line 1 column 1 (char 0)", 0),
    (
      b"ll", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (b"nul", "unexpected end of data: line 1 column 4 (char 3)", 3),
    (b"n", "unexpected end of data: line 1 column 2 (char 1)", 1),
    (
      b"jNull", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (b"nl3l", "invalid literal, expected 'null': line 1 column 1 (char 0)", 0),
    (
      b"`", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (b"nuul", "invalid literal, expected 'null': line 1 column 1 (char 0)", 0),
    (
      b"uN", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (b"nuLJl", "invalid literal, expected 'null': line 1 column 1 (char 0)", 0),
    (b"nllu", "invalid literal, expected 'null': line 1 column 1 (char 0)", 0),
    (
      b"uunlll", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (b"nfull", "invalid literal, expected 'null': line 1 column 1 (char 0)", 0),
    (b"n", "unexpected end of data: line 1 column 2 (char 1)", 1),
    (
      b"N", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (b"", "Input is a zero-length, empty document: line 1 column 1 (char 0)", 0),
    (b"", "Input is a zero-length, empty document: line 1 column 1 (char 0)", 0),
    (
      b"luln", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (b"\"hll", "unexpected end of data: line 1 column 5 (char 4)", 4),
    (b"\"", "unexpected end of data: line 1 column 2 (char 1)", 1),
    (
      b"\"h\"ol", "unexpected content after document: line 1 column 4 (char 3)",
      3,
    ),
    (b"\"hello", "unexpected end of data: line 1 column 7 (char 6)", 6),
    (
      b"eh\"llO", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (b"", "Input is a zero-length, empty document: line 1 column 1 (char 0)", 0),
    (
      b"hell", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (
      b"hel\"o", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (b"", "Input is a zero-length, empty document: line 1 column 1 (char 0)", 0),
    (
      b"z\"lehlo", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (
      b"Hellor\"", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (
      b"\"hhello\"1", "unexpected content after document: line 1 column 9 (char 8)",
      8,
    ),
    (
      b"\"hllo\"*", "unexpected content after document: line 1 column 7 (char 6)",
      6,
    ),
    (b"", "Input is a zero-length, empty document: line 1 column 1 (char 0)", 0),
    (b"123.b45;6", "no digit after decimal point: line 1 column 5 (char 4)", 4),
    (b"1263.p456", "no digit after decimal point: line 1 column 6 (char 5)", 5),
    (
      b"123d.456", "unexpected content after document: line 1 column 4 (char 3)",
      3,
    ),
    (b"", "Input is a zero-length, empty document: line 1 column 1 (char 0)", 0),
    (b"", "Input is a zero-length, empty document: line 1 column 1 (char 0)", 0),
    (b"", "Input is a zero-length, empty document: line 1 column 1 (char 0)", 0),
    (
      b"`123.456", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (
      b"j{\"k\"", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (
      b"n{:k\"\" \"v\"}", "invalid literal, expected 'null': line 1 column 1 (char 0)",
      0,
    ),
    (
      b"\"lk\": \"v", "unexpected content after document: line 1 column 5 (char 4)",
      4,
    ),
    (
      b"{v\":\"k\"}", "unexpected character, expected a string key: line 1 column 2 (char 1)",
      1,
    ),
    (b"{", "unexpected end of data: line 1 column 2 (char 1)", 1),
    (
      b"{\"k3\": \"v\"d}", "unexpected character, expected ',' or '}': line 1 column 11 (char 10)",
      10,
    ),
    (
      b"{\"K\"\" \"v:}", "unexpected character, expected ':' after key: line 1 column 5 (char 4)",
      4,
    ),
    (b"{\"", "unexpected end of data: line 1 column 3 (char 2)", 2),
    (
      b"\"\"k\": \"v{}", "unexpected content after document: line 1 column 3 (char 2)",
      2,
    ),
    (b"{\"k\": \"v\"", "unexpected end of data: line 1 column 10 (char 9)", 9),
    (
      b"{\"k:} \"v\"}", "unexpected character, expected ':' after key: line 1 column 8 (char 7)",
      7,
    ),
    (
      b"{\"k\":k\"\"v }", "unexpected character, expected a JSON value: line 1 column 6 (char 5)",
      5,
    ),
    (
      b"{\"k\"j: \"v\"}", "unexpected character, expected ':' after key: line 1 column 5 (char 4)",
      4,
    ),
    (
      b"\"k\":\"\"v }", "unexpected content after document: line 1 column 4 (char 3)",
      3,
    ),
    (b"{\"k\":\"", "unexpected end of data: line 1 column 7 (char 6)", 6),
    (b"[8", "unexpected end of data: line 1 column 3 (char 2)", 2),
    (b"[[[[]]", "unexpected end of data: line 1 column 7 (char 6)", 6),
    (b"[[[[]]]", "unexpected end of data: line 1 column 8 (char 7)", 7),
    (
      b"[z[[[]]]]", "unexpected character, expected a JSON value: line 1 column 2 (char 1)",
      1,
    ),
    (
      b"[o[][]][]", "unexpected character, expected a JSON value: line 1 column 2 (char 1)",
      1,
    ),
    (
      b"[[[]]]]", "unexpected content after document: line 1 column 7 (char 6)",
      6,
    ),
    (
      b"[[[[]]h]]", "unexpected character, expected ',' or ']': line 1 column 7 (char 6)",
      6,
    ),
    (b"", "Input is a zero-length, empty document: line 1 column 1 (char 0)", 0),
    (b"[", "unexpected end of data: line 1 column 2 (char 1)", 1),
    (
      b"[[]]][]", "unexpected content after document: line 1 column 5 (char 4)",
      4,
    ),
    (b"[[", "unexpected end of data: line 1 column 3 (char 2)", 2),
    (
      b"][[]]][[", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (
      b"[[[[;]]]]", "unexpected character, expected a JSON value: line 1 column 5 (char 4)",
      4,
    ),
    (b"[[[", "unexpected end of data: line 1 column 4 (char 3)", 3),
    (b"[[[[]]]", "unexpected end of data: line 1 column 8 (char 7)", 7),
    (
      b"[[[6[]]]]", "unexpected character, expected ',' or ']': line 1 column 5 (char 4)",
      4,
    ),
    (
      b"l[[E[[]]]]", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (b"[[[[]", "unexpected end of data: line 1 column 6 (char 5)", 5),
    (b"[[[", "unexpected end of data: line 1 column 4 (char 3)", 3),
    (
      b"{fa\": 1, \"b\": [true, \"alse,null, \"s\"]}", "unexpected character, expected a string key: line 1 column 2 (char 1)",
      1,
    ),
    (
      b"{\"a\": 1, \"b\"7: [true, false, null, \"s\"]}", "unexpected character, expected ':' after key: line 1 column 13 (char 12)",
      12,
    ),
    (
      b"{\"a\": 1, \"b\": [true, fAlse, null, \"s\"]}", "invalid literal, expected 'false': line 1 column 22 (char 21)",
      21,
    ),
    (
      b"{\"a\": 1c, sb\": [true,2 false, null, \"\"\"]}", "unexpected character, expected ',' or '}': line 1 column 8 (char 7)",
      7,
    ),
    (
      b"{\"a\": 1, \"b\":n[true, Fals},  ull, \"s\"]e", "invalid literal, expected 'null': line 1 column 14 (char 13)",
      13,
    ),
    (
      b"{a\": 1, \"b\": [true,fal,e, nulls \"s\"]}", "unexpected character, expected a string key: line 1 column 2 (char 1)",
      1,
    ),
    (b"{\"a", "unexpected end of data: line 1 column 4 (char 3)", 3),
    (
      b"{\"a\": 1, \"b\": [true, false, null, \"s\"}", "unexpected character, expected ',' or ']': line 1 column 38 (char 37)",
      37,
    ),
    (
      b"{\"\": 1, \"b\"", "unexpected end of data: line 1 column 12 (char 11)", 11,
    ),
    (
      b"{\"a\"[ 1, \"b\": :true, false, null, \"s\"]}", "unexpected character, expected ':' after key: line 1 column 5 (char 4)",
      4,
    ),
    (
      b"{\"a\": 1, \"b\": [true, false null, \"s\"]}", "unexpected character, expected ',' or ']': line 1 column 28 (char 27)",
      27,
    ),
    (
      b"{\"a\": 1, \"b\": [true, falqse, null, \"s\"]}", "invalid literal, expected 'false': line 1 column 22 (char 21)",
      21,
    ),
    (
      b"{\"a\": 1, \"b\": [true, false, nul, \"s\"]}", "invalid literal, expected 'null': line 1 column 29 (char 28)",
      28,
    ),
    (
      b"{\"a\": 1, \"b\": [true, false, null, \"s]}", "unexpected end of data: line 1 column 39 (char 38)",
      38,
    ),
    (
      b"{\"a\": 1, \"b\"", "unexpected end of data: line 1 column 13 (char 12)",
      12,
    ),
    (
      b"{\"a\": 1, \"b\": [tlrue, false, null, \"fs\"]}", "invalid literal, expected 'true': line 1 column 16 (char 15)",
      15,
    ),
    (
      b"u\"a\": 1, \"b\": ltr{e, fa[se, nu", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (
      b"{\"a\": 1, lb\": [tru, flse, nul\", \"s\"]}", "unexpected character, expected a string key: line 1 column 10 (char 9)",
      9,
    ),
    (
      b"  {dspace\"\":  [1,\x0a2", "unexpected character, expected a string key: line 1 column 4 (char 3)",
      3,
    ),
    (
      b"  {\"spaced\": [1,\x0a2", "unexpected end of data: line 2 column 2 (char 18)",
      18,
    ),
    (
      b"  {\"spacd\":  [1,", "unexpected end of data: line 1 column 17 (char 16)",
      16,
    ),
    (
      b"  {\"spaceD\":1 [ ,\x0a2", "unexpected character, expected ',' or '}': line 1 column 15 (char 14)",
      14,
    ),
    (
      b"  {w\"spaced\":  [1,\x0a2,\x0a3]}  ", "unexpected character, expected a string key: line 1 column 4 (char 3)",
      3,
    ),
    (
      b"  {\"spac8ed\":   1,\x0a2,\x0a[]}3 ", "unexpected character, expected a string key: line 2 column 1 (char 19)",
      19,
    ),
    (b"  {", "unexpected end of data: line 1 column 4 (char 3)", 3),
    (
      b"  {\"spaced\"  :[1,\x0a2\x0a3]}  ", "unexpected character, expected ',' or ']': line 3 column 1 (char 20)",
      20,
    ),
    (
      b"s  {\"s[paced\":  [1,\x0a2,\x0a3]}  ", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (
      b"  {\"spaced\"  [1,\x0a2,\x0a3]}  ", "unexpected character, expected ':' after key: line 1 column 14 (char 13)",
      13,
    ),
    (
      b"s {\" paced\":  [1,\x0a2,\x0a3]}  ", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (
      b"  {\"spaced\":  [1,\x0a2,\x0a3h]}  ", "unexpected character, expected ',' or ']': line 3 column 2 (char 22)",
      22,
    ),
    (
      b"\" {\"spaed :  [1,\x0a2,\x0a ]} 3", "unexpected content after document: line 1 column 5 (char 4)",
      4,
    ),
    (
      b" {\"spa:ed\"c  [1,\x0a2,\x0a3]}  ", "unexpected character, expected ':' after key: line 1 column 11 (char 10)",
      10,
    ),
    (
      b"  {\"spaced\"{:  [1,\x0a2,\x0a83]}  ", "unexpected character, expected ':' after key: line 1 column 12 (char 11)",
      11,
    ),
    (
      b"  {\"spaced\": [1,\x0a2,\x0a3]|}  ", "unexpected character, expected ',' or '}': line 3 column 3 (char 22)",
      22,
    ),
    (
      b"  {\"s aced\":  [1,\x0a2,\x0a3]}p ", "unexpected content after document: line 3 column 4 (char 24)",
      24,
    ),
    (
      b"\x00", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (
      b"\xff", "str is not valid UTF-8: surrogates not allowed: line 1 column 1 (char 0)",
      0,
    ),
    (
      b"\x80", "str is not valid UTF-8: surrogates not allowed: line 1 column 1 (char 0)",
      0,
    ),
    (
      b"\xed\xa0\x80", "str is not valid UTF-8: surrogates not allowed: line 1 column 1 (char 0)",
      0,
    ),
    (
      b"\xef\xbb\xbf", "UTF-8 byte order mark (BOM) is not supported: line 1 column 1 (char 0)",
      0,
    ),
    (
      b"\xef\xbb\xbf{}", "UTF-8 byte order mark (BOM) is not supported: line 1 column 1 (char 0)",
      0,
    ),
    (
      b"\xc0\xaf", "str is not valid UTF-8: surrogates not allowed: line 1 column 1 (char 0)",
      0,
    ),
    (
      b"\xf4\x90\x80\x80", "str is not valid UTF-8: surrogates not allowed: line 1 column 1 (char 0)",
      0,
    ),
    (
      b"\xe2\x82", "str is not valid UTF-8: surrogates not allowed: line 1 column 1 (char 0)",
      0,
    ),
    (
      b"{\"a\": \"\xff\"}", "str is not valid UTF-8: surrogates not allowed: line 1 column 1 (char 0)",
      0,
    ),
    (
      b"{\"a\": 1} \xff", "str is not valid UTF-8: surrogates not allowed: line 1 column 1 (char 0)",
      0,
    ),
    (
      b"\"\xf0\x9f\x98\"", "str is not valid UTF-8: surrogates not allowed: line 1 column 1 (char 0)",
      0,
    ),
    (b"   ", "input data is empty: line 1 column 1 (char 0)", 0),
    (b"\x0a\x0a", "input data is empty: line 1 column 1 (char 0)", 0),
    (b"\x09", "input data is empty: line 1 column 1 (char 0)", 0),
    (b"\x0d", "input data is empty: line 1 column 1 (char 0)", 0),
    (b"-", "unexpected end of data: line 1 column 2 (char 1)", 1),
    (b"+1", "no digit after sign: line 1 column 1 (char 0)", 0),
    (b".5", "no digit after sign: line 1 column 1 (char 0)", 0),
    (
      b"01", "number with leading zero is not allowed: line 1 column 1 (char 0)",
      0,
    ),
    (b"1.", "unexpected end of data: line 1 column 3 (char 2)", 2),
    (b"1e", "unexpected end of data: line 1 column 3 (char 2)", 2),
    (b"1e+", "unexpected end of data: line 1 column 4 (char 3)", 3),
    (b"--1", "no digit after sign: line 1 column 2 (char 1)", 1),
    (b"0x10", "unexpected content after document: line 1 column 2 (char 1)", 1),
    (b"tru", "unexpected end of data: line 1 column 4 (char 3)", 3),
    (b"fals", "unexpected end of data: line 1 column 5 (char 4)", 4),
    (b"nul", "unexpected end of data: line 1 column 4 (char 3)", 3),
    (
      b"TRUE", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (
      b"[1 2]", "unexpected character, expected ',' or ']': line 1 column 4 (char 3)",
      3,
    ),
    (
      b"{\"a\" \"b\"}", "unexpected character, expected ':' after key: line 1 column 6 (char 5)",
      5,
    ),
    (
      b"{1:2}", "unexpected character, expected a string key: line 1 column 2 (char 1)",
      1,
    ),
    (
      b"[}", "unexpected character, expected a JSON value: line 1 column 2 (char 1)",
      1,
    ),
    (
      b"{]", "unexpected character, expected a string key: line 1 column 2 (char 1)",
      1,
    ),
    (
      b"}{", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (b"[]]", "unexpected content after document: line 1 column 3 (char 2)", 2),
    (
      b"\"\\x41\"", "invalid escaped sequence in string: line 1 column 2 (char 1)",
      1,
    ),
    (
      b"\"\\u12\"", "invalid escaped sequence in string: line 1 column 2 (char 1)",
      1,
    ),
    (
      b"\"\\uZZZZ\"", "invalid escaped sequence in string: line 1 column 2 (char 1)",
      1,
    ),
    (
      b"\"unterminated", "unexpected end of data: line 1 column 14 (char 13)", 13,
    ),
    (
      b"{\"a\": }", "unexpected character, expected a JSON value: line 1 column 7 (char 6)",
      6,
    ),
    (
      b"[,]", "unexpected character, expected a JSON value: line 1 column 2 (char 1)",
      1,
    ),
    (
      b"{,}", "unexpected character, expected a string key: line 1 column 2 (char 1)",
      1,
    ),
    (
      b"[1,,2]", "unexpected character, expected a JSON value: line 1 column 4 (char 3)",
      3,
    ),
    (
      b"{\"a\":1,}", "trailing comma is not allowed: line 1 column 7 (char 6)", 6,
    ),
    (b"1 2", "unexpected content after document: line 1 column 3 (char 2)", 2),
    (
      b"\"a\" b", "unexpected content after document: line 1 column 5 (char 4)",
      4,
    ),
    (
      b"[1]\x0a[2]", "unexpected content after document: line 2 column 1 (char 4)",
      4,
    ),
    (
      b"[\x0a  1,\x0a  2\x0a  ", "unexpected end of data: line 4 column 3 (char 13)",
      13,
    ),
    (
      b"['single']", "unexpected character, expected a JSON value: line 1 column 2 (char 1)",
      1,
    ),
    (
      b"{a: 1}", "unexpected character, expected a string key: line 1 column 2 (char 1)",
      1,
    ),
    (
      b"NaN", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (
      b"Infinity", "unexpected character, expected a JSON value: line 1 column 1 (char 0)",
      0,
    ),
    (b"-Infinity", "no digit after sign: line 1 column 2 (char 1)", 1),
    (
      b"1e999", "number is infinity when parsed as double: line 1 column 1 (char 0)",
      0,
    ),
    (
      b"-1e999", "number is infinity when parsed as double: line 1 column 1 (char 0)",
      0,
    ),
    (b"1.2.3", "unexpected content after document: line 1 column 4 (char 3)", 3),
    (b"..1", "no digit after sign: line 1 column 1 (char 0)", 0),
  ]
}

///|
test "decode errors fuzz vs orjson" {
  for case in err_cases() {
    let (input, message, position) = case
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
}
