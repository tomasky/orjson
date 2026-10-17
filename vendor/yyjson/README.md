# Vendored yyjson

This directory contains the [yyjson](https://github.com/ibireme/yyjson) sources
as vendored and modified by [orjson](https://github.com/ijl/orjson) 3.13.0
(`include/yyjson/`). The local copy is kept byte-for-byte identical to the
orjson version so that parsing behavior matches orjson exactly.

Notes:

- This is a modified yyjson. In particular `yyjson_read_opts()` takes four
  arguments (`dat`, `len`, `alc`, `err`); the `flg` parameter was removed by
  orjson.
- yyjson is distributed under the MIT license (see the header of `yyjson.c` /
  `yyjson.h`).
- The modifications made by orjson are distributed under the MPL-2.0 license
  (see `../LICENSE-MPL-2.0`). `../LICENSE-MIT` and `../LICENSE-APACHE` are the
  licenses of the original orjson project.

Do not edit `yyjson.c` / `yyjson.h`; configuration is applied in
`../../c/yyjson_impl.c`.
