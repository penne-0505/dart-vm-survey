**Title**

[vm] Failing `as FutureOr<T>` on a Smi crashes with SIGSEGV instead of throwing TypeError (JIT and AOT)

**Body**

If a heap object passes an `as FutureOr<T>` check first, a later Smi (an `int` that isn't a subtype of `T`) at the same check site crashes the VM with SIGSEGV instead of throwing `TypeError`.

```dart
import 'dart:async';

void check(Object? x) {
  try {
    x as FutureOr<String>;
    print('ok: $x');
  } on TypeError catch (e) {
    print('TypeError: $e');
  }
}

void main() {
  check('a');
  check(42);
}
```

Expected: the second call prints `TypeError`.
Actual: prints `ok: a`, then the VM crashes:

```
si_signo=Segmentation fault(11), si_code=SEGV_MAPERR(1), si_addr=0x53
  pc 0x00007f6515805240 fp 0x00007f6514ffe338 [Stub] Subtype2TestCache+0x10
  pc 0x00007f651582d075 fp 0x00007f6514ffe380 [Unoptimized] check+0xa5
```

<details><summary>Full crash output</summary>

```
$ dart run repro.dart
ok: a

===== CRASH =====
si_signo=Segmentation fault(11), si_code=SEGV_MAPERR(1), si_addr=0x53
version=3.15.0-27.0.dev (dev) (Tue Oct 13 17:03:34 2026 -0700) on "linux_x64"
pid=3254357, thread=3254431, isolate_group=main(0x561cd815b930), isolate=main(0x561cd81822d0)
os=linux, arch=x64, comp=no, sim=no
isolate_instructions=561ca58ad340, vm_instructions=0
fp=7f6514ffe338, sp=7f6514ffe308, pc=7f6515805240
  pc 0x00007f6515805240 fp 0x00007f6514ffe338 [Stub] Subtype2TestCache+0x10
  pc 0x00007f651582d075 fp 0x00007f6514ffe380 [Unoptimized] check+0xa5
  pc 0x00007f651582cf8d fp 0x00007f6514ffe3b0 [Unoptimized] main+0x8d
  pc 0x00007f651582cec6 fp 0x00007f6514ffe3d8 [Unoptimized] main+0x76
  pc 0x00007f651582cdeb fp 0x00007f6514ffe450 [Unoptimized] _Closure@0150898.dyn:call+0x7fb
  pc 0x00007f651582b7ef fp 0x00007f6514ffe490 [Unoptimized] _delayEntrypointInvocation@1026248.<anonymous closure>+0x2cf
  pc 0x00007f651582b4be fp 0x00007f6514ffe510 [Unoptimized] _Closure@0150898.dyn:call+0x82e
  pc 0x00007f651582a23e fp 0x00007f6514ffe568 [Unoptimized] _RawReceivePort@1026248._handleMessage@1026248+0x19e
  pc 0x00007f6515803547 fp 0x00007f6514ffe5e0 [Stub] InvokeDartCode+0x97
  pc 0x0000561ca5aa2804 fp 0x00007f6514ffe650 dart::DartEntry::InvokeFunction+0xd4
  pc 0x0000561ca5aa44e2 fp 0x00007f6514ffe690 dart::DartLibraryCalls::HandleMessage+0x122
  pc 0x0000561ca5ac43e2 fp 0x00007f6514ffec00 dart::IsolateMessageHandler::HandleMessage+0x322
  pc 0x0000561ca5ae8a3f fp 0x00007f6514ffec70 dart::MessageHandler::HandleMessages+0x12f
  pc 0x0000561ca5ae86f2 fp 0x00007f6514ffecc0 dart::MessageHandler::TaskCallback+0x192
  pc 0x0000561ca5bd4367 fp 0x00007f6514ffed20 dart::ThreadPool::WorkerLoop+0x117
  pc 0x0000561ca5bd45d2 fp 0x00007f6514ffed50 dart::ThreadPool::Worker::Main+0x82
  pc 0x0000561ca5b7c5c9 fp 0x00007f6514ffee10 dart::ThreadStart+0xd9
  pc 0x00007f6516e98042 fp 0x00007f6514ffef30 /usr/lib/libc.so.6+0x98042
-- End of DumpStackTrace
  pc 0x00007f6515805240 fp 0x00007f6514ffe338 sp 0x00007f6514ffe308 [Stub] SlowTypeTest+0xfffffffffffff3a0
  pc 0x00007f651582d075 fp 0x00007f6514ffe380 sp 0x00007f6514ffe348 [Unoptimized] check+0xa5
  pc 0x00007f651582cf8d fp 0x00007f6514ffe3b0 sp 0x00007f6514ffe390 [Unoptimized] main+0x8d
  pc 0x00007f651582cec6 fp 0x00007f6514ffe3d8 sp 0x00007f6514ffe3c0 [Unoptimized] main+0x76
  pc 0x00007f651582cdeb fp 0x00007f6514ffe450 sp 0x00007f6514ffe3e8 [Unoptimized] _Closure@0150898.dyn:call+0x7fb
  pc 0x00007f651582b7ef fp 0x00007f6514ffe490 sp 0x00007f6514ffe460 [Unoptimized] _delayEntrypointInvocation@1026248.<anonymous closure>+0x2cf
  pc 0x00007f651582b4be fp 0x00007f6514ffe510 sp 0x00007f6514ffe4a0 [Unoptimized] _Closure@0150898.dyn:call+0x82e
  pc 0x00007f651582a23e fp 0x00007f6514ffe568 sp 0x00007f6514ffe520 [Unoptimized] _RawReceivePort@1026248._handleMessage@1026248+0x19e
  pc 0x00007f6515803547 fp 0x00007f6514ffe5e0 sp 0x00007f6514ffe578 [Stub] Entry frame
Aborted (SIGABRT)
```

</details>

- Crashes with both `dart run` and `dart compile exe`.
- Reproduced on linux_x64 with 3.10.7, 3.13.2–3.13.5 (stable), 3.14.0-315.1.beta and 3.15.0-27.0.dev.
- Without the preceding `check('a')`, `check(42)` throws `TypeError` as expected.
- `x as String` (a non-`FutureOr` type) throws `TypeError` as expected.
- In a real app this came from returning a decoded JSON value from an `async` function declared to return `Future<String>` (e.g. `return json['id'];` where `id` is a number).

This looks like the same issue as the iOS AOT crash in flutter/flutter#162375 (`Subtype2TestCache` ← `SlowTypeTest`).
