/* Compiles the vendored yyjson (orjson's fork) with the configuration in
 * yyjson_conf.h. This file only exists so that the defines are applied to
 * yyjson.c itself without patching the vendored sources. */
#include "yyjson_conf.h"

#include "../vendor/yyjson/yyjson.c"
