# Vendored yyjson

This directory contains the [yyjson](https://github.com/ibireme/yyjson) sources
as vendored and modified by [orjson](https://github.com/ijl/orjson) 3.13.0
(`include/yyjson/`). The local copy is kept byte-for-byte identical to the
orjson version so that parsing behavior matches orjson exactly.

Notes:

- Upstream pin: orjson **3.13.0**, `include/yyjson/yyjson.c` and `yyjson.h`
  (yyjson 0.12.0 base, orjson commit `1ea2fb0`). To re-verify against a new
  orjson release:

    ```sh
    pip3 download orjson --no-binary :all: --no-deps -d /tmp/oj
    tar xf /tmp/oj/orjson-*.tar.gz -C /tmp/oj
    diff -r /tmp/oj/orjson-*/include/yyjson vendor/yyjson
    ```

  Only this README may show up as a difference.

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
