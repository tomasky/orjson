/*
 * ThreadSanitizer race driver for the bridge's error-message global.
 *
 * 并不能被 moon 编译或运行；这是开发期验证工具。两个线程反复触发
 * mb_fail()（写 mb_orjson_build_err）并经 mb_orjson_build_error() 读回。
 * moonbit 运行时以桩代替（见下方 stub 区）。
 *
 * 构建与运行（在仓库根目录）：
 *   cc -fsanitize=thread -Og -I/root/.moon/include -Ic \
 *      c/tsan_race_driver.c vendor/yyjson/yyjson.c -o /tmp/race_bin -lpthread
 *   /tmp/race_bin
 *
 * 期望：修复后（mb_orjson_build_err 为 _Thread_local）输出 "race driver done"
 * 且无 WARNING；把 _Thread_local 去掉重跑，TSan 必须报 data race。
 */
#include <stdint.h>
#include "/root/.moon/include/moonbit.h"
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ---- moonbit 运行时桩（仅覆盖被触发路径用到的符号） ---- */
moonbit_string_t moonbit_make_string_raw(int32_t size) {
  /* 8 字节对象头（rc + meta）+ size 个 uint16；meta 必须是元素数 */
  uint16_t *base = (uint16_t *)calloc((size_t)size * 2 + 8, 1);
  ((uint32_t *)base)[1] = (uint32_t)size;
  return base + 4;
}
void moonbit_incref(void *obj) {}
void moonbit_decref(void *obj) {}

/* ---- 被测源码 ---- */
/* 被测源码（本文件位于 c/ 下，直接相对引用） */
#include "bridge.c"

static void *worker(void *arg) {
  (void)arg;
  /* 孤立代理项 → mb_utf8_from_utf16 报 invalid → mb_fail(MB_ERR_INVALID_STR) */
  uint16_t lone[1] = {0xD800};
  for (int i = 0; i < 200; i++) {
    void *n = mb_orjson_build_string(lone);
    (void)n;
    moonbit_string_t msg = mb_orjson_build_error();
    (void)msg;
  }
  return NULL;
}

int main(void) {
  pthread_t t1, t2;
  pthread_create(&t1, NULL, worker, NULL);
  pthread_create(&t2, NULL, worker, NULL);
  pthread_join(t1, NULL);
  pthread_join(t2, NULL);
  printf("race driver done\n");
  return 0;
}
