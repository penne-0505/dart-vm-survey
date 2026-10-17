# Minimal reproduction: failing `as FutureOr<T>` on a Smi crashes the VM

All files are self-contained and use only `dart:*` (and `flutter_test` for the
Flutter variant).

| File | What it shows |
|---|---|
| `futureor_cast_smi.dart` | Smallest form: `x as FutureOr<String>` with `'a'`, then `42` |
| `async_return_smi.dart` | Same bug through the implicit return check of an `async` function |
| `order_dependence.dart` | The first Smi gets the expected TypeError; a Smi after a passing String crashes |
| `hot_loop_variant.dart` | Same crash from JIT-optimized code |
| `json_decode_await_variant.dart` | `return await json.decode(...)` in `Future<String>`; Smi 0 faults at `0xffffffffffffffff` |
| `control_plain_type.dart` | Control: the same sequence against `String` (not `FutureOr`) works |
| `flutter_bundle/` | Flutter test form: two test files pass separately, crash when bundled or merged into one file |

## Run

```sh
dart run futureor_cast_smi.dart          # JIT
dart compile exe futureor_cast_smi.dart -o f.exe && ./f.exe   # AOT

cd flutter_bundle
flutter pub get
flutter test --concurrency=1 test/a_string_id_test.dart test/b_int_id_test.dart  # passes
flutter test --concurrency=1 test/bundle.dart                                  # segfault
flutter test --concurrency=1 test/single_file_test.dart                        # segfault
```

## Expected

```
ok: a
TypeError: type 'int' is not a subtype of type 'FutureOr<String>' in type cast
```

## Actual (Dart 3.13.5, linux_x64, JIT and AOT)

```
ok: a

===== CRASH =====
si_signo=Segmentation fault(11), si_code=SEGV_MAPERR(1), si_addr=0x53
  pc ... [Stub] Subtype2TestCache+0x10
  pc ... [Unoptimized] check+0xa5
```
