**Title:** [vm] SIGSEGV in Subtype2TestCache stub when a failing `as FutureOr<T>` check receives a Smi after the check site cached a heap object

**Summary.** A type check against `FutureOr<T>` crashes with SIGSEGV instead of throwing `TypeError` when both of these hold:

1. The check fails because the value is a Smi and `int` is not a subtype of `T` (e.g. `FutureOr<String>`, `FutureOr<double>`, `FutureOr<List<int>>`).
2. The same check site passed earlier for a heap object, so the call site's SubtypeTestCache is non-null.

The check can be an explicit `as`, or the implicit check on `return <dynamic>` in an `async` function that returns `Future<T>`. It reproduces in JIT (unoptimized and optimized code) and AOT on linux_x64, in Dart 3.10.7 through 3.13.5.

**Repro.**
```dart
import 'dart:async';
void check(Object? x) {
  try { x as FutureOr<String>; print('ok: $x'); }
  on TypeError catch (e) { print('TypeError: $e'); }
}
void main() { check('a'); check(42); }
```
Async form:
```dart
Future<String> pictureId(Map<String, dynamic> body) async => body['picture_id'];
Future<void> main() async {
  print(await pictureId({'picture_id': 'picture-1'}));
  try { print(await pictureId({'picture_id': 42})); } on TypeError catch (e) { print('TypeError: $e'); }
}
```

**Expected:** `ok: a`, then `TypeError: type 'int' is not a subtype of type 'FutureOr<String>' in type cast`.

**Actual:**
```
===== CRASH =====
si_signo=Segmentation fault(11), si_code=SEGV_MAPERR(1), si_addr=0x53
version=3.13.5 (stable) (Tue Sep 29 01:00:52 2026 -0700) on "linux_x64"
  pc ... [Stub] Subtype2TestCache+0x10
  pc ... [Unoptimized] check+0xa5
```
`si_addr` is the raw Smi minus the heap-object tag (`0x54 - 1`). With the Smi `0` it is `0xffffffffffffffff`.

**Environment.** Linux x86_64. Dart 3.10.7 (2da4111d8d0c), 3.13.2 (60a57cd42d64), 3.13.3 (1d1a730ef918), 3.13.4 (b530c21f7de3), 3.13.5 (04bcd1036cdc), all via Flutter 3.38.7 / 3.47.2 / 3.47.4 / 3.47.5 / 3.47.7. All crash with `dart run` and in `flutter test`. 3.13.5 also crashes with `dart compile exe`.

These flags make no difference: `--optimization-counter-threshold=-1`, `--optimization-counter-threshold=1 --no-background-compilation`, `--no-use-osr`, `--max-subtype-cache-entries=0`, `--enable-asserts`, `--no-eliminate-type-checks`.

**Scope.**
- Crashes: `FutureOr<String>`, `FutureOr<String>?`, `FutureOr<FutureOr<String>>`, `FutureOr<Pattern>`, `FutureOr<double>`, `FutureOr<List<int>>`.
- Correct `TypeError`: `String`, `Pattern`, `Comparable<String>`, `Future<String>`, `List<int>`.
- Smi correctly accepted: `FutureOr<num>`, `FutureOr<Object>`.
- If the Smi is the first value at the site (STC still null), the `TypeError` is correct.

**Analysis (at 04bcd1036cdc).**
- The crash is at `Subtype2TestCache+0x10`: `movl r10d,[rax-1]; shrl r10d,12; cmpq r10,0x39` with `rax=0x54`. That is `LoadClassId` plus the `kClosureCid` comparison in `GenerateSubtypeNTestCacheStub`, which uses `LoadClassId` for `n < 3` with the comment "this code should never be called with a Smi instance".
- `SubtypeTestCache::UsedInputsForType` returns 2 for an instantiated `Type`, so the STC created for `FutureOr<String>` has 2 inputs.
- `GenerateCallerChecksForAssertAssignable` filters Smis only when `int <: dst_type`.
- `FutureOr<T>` gets no specialized TTS (`BuildCodeForType` returns null), so it uses `DefaultTypeTest`, which jumps to `SlowTypeTest`. `SlowTypeTest` dispatches on the STC's input count without a Smi check, so the Smi reaches `Subtype2TestCache`.
- Related: ffddb2231f0d ("[modular_aot] Fix TypeTest to reject Smis before calling STC") states "SubtypeTestCache stubs do not support Smis for n < 3" but changes only `pkg/native_compiler`. On `main` (read 2026-10-16) the code above looks unchanged. I have not run a `main` build.

**Possible fix (untested).** Either branch to `call_runtime` in `GenerateSlowTypeTestStub` when the instance is a Smi, before calling the 1- and 2-input STC stubs, or use `LoadClassIdMayBeSmi` for all `n`.

**Impact.** Code that should get a catchable `TypeError` crashes the process. In AOT this means release builds. A common way to hit it is `return jsonValue;` from a `Future<String>` async function when the JSON holds a number. flutter/flutter#162375 (iOS release, fault at `0xffffffffffffffff` near `return await json.decode(result);`, fixed by its reporter with an `is String` check) may be this bug. That is unconfirmed, but the same shape faults at the same address on x64 JIT and AOT.

**Workaround.** Cast explicitly to the non-`FutureOr` type, e.g. `return body['picture_id'] as String;`, or check with `is` before returning.

Sources:
- [dart-lang/sdk#63413](https://github.com/dart-lang/sdk/issues/63413)
- [dart-lang/sdk#61635](https://github.com/dart-lang/sdk/issues/61635)
- [flutter/flutter#162375](https://github.com/flutter/flutter/issues/162375)
- [dart-lang/sdk#34238](https://github.com/dart-lang/sdk/issues/34238)
- [dart-lang/sdk#52536](https://github.com/dart-lang/sdk/issues/52536)
- [dart-lang/sdk#48937](https://github.com/dart-lang/sdk/issues/48937)
- commit [ffddb2231f0d](https://github.com/dart-lang/sdk/commit/ffddb2231f0d7bd86b367ce3c05df416beca299d)
- commit [3bb2d53b5bfa](https://github.com/dart-lang/sdk/commit/3bb2d53b5bfa9bf82a5a79fb91efb72dc4d98c91)