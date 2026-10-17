これは Dart VM の不具合とみてよいと考えます。確度は高いです。最小の再現は、会社のコードを含まない形で `/home/penne/dev/scratch/dart-vm-survey/repro/` に置きました。報告の下書きは本文の最後に英語で載せています。`report-draft.md` は書き出せていません。ハーネスが `.md` の報告ファイルの作成を拒否したため、このメッセージに載せました。

## 結論

- **原因の部品**: 型検査の実行時の経路にある `SlowTypeTest` スタブと、そこから呼ばれる `Subtype2TestCache` スタブです。JIT の最適化は関係ありません。最適化前のコードでも最適化後のコードでも落ち、AOT でも落ちます。
- **起きる条件**: `FutureOr<T>` への型検査で、検査が失敗する Smi（小さい整数）が来たときです。`T` には `int` を含まない型が入ります（`String`、`double`、`List<int>` など）。同じ検査箇所がそれより前に一度通っていると、検査結果のキャッシュ（SubtypeTestCache）が作られており、そこに Smi が入って SIGSEGV になります。本来は `TypeError` が投げられるはずの場面です。
- **会社のケースとの対応**: 偽の応答の `picture_id` が `'picture-1'` から `42` に変わる流れです。`async` の閉包が `return responseBody['picture_id']` を返すと、`dynamic` を `Future<String>` として返すので、VM が暗黙に `FutureOr<String>` への検査を入れます。この行の後ろに `as String` を足すと、2 ファイルを束ねた実行が 31 本すべて通りました。展開したコピーの上で確かめ、ファイルは元に戻しています。

## 最小の再現

`repro/futureor_cast_smi.dart`:

```dart
import 'dart:async';
void check(Object? x) {
  try { x as FutureOr<String>; print('ok: $x'); }
  on TypeError catch (e) { print('TypeError: $e'); }
}
void main() { check('a'); check(42); }
```

- **期待**: `ok: a` の次に `TypeError: type 'int' is not a subtype of type 'FutureOr<String>' in type cast`
- **実際**: `ok: a` の次に `si_addr=0x53` で SIGSEGV。落ちる場所は `[Stub] Subtype2TestCache+0x10` です。

同じフォルダの他のファイルと結果は次のとおりです。

| ファイル | 内容と結果 |
|---|---|
| `async_return_smi.dart` | `async` の return の暗黙の検査で落ちる |
| `order_dependence.dart` | 最初の Smi は正しく `TypeError`。String が通った後の Smi で落ちる |
| `hot_loop_variant.dart` | 最適化後のコードから落ちる |
| `json_decode_await_variant.dart` | `return await json.decode(...)` の形。Smi の 0 で `si_addr=0xffffffffffffffff` |
| `control_plain_type.dart` | 対照。`as String` では正しく `TypeError` |
| `flutter_bundle/` | Flutter のテスト版。2 ファイルを別々に流すと通る。束ねても、1 ファイルにまとめても落ちる |

実行手順は `repro/README.md` に書きました。

## 証拠

証拠のファイルはすべて `/home/penne/dev/scratch/dart-vm-survey/evidence/` の下にあります。

- **flutter_tester のコアダンプ**（今日の再現、PID 2914706）: `core_2914706_flutter_tester_3477.txt`。`rax=0x54` で、命令の並びは単体の `dart` の `Subtype2TestCache` スタブ（`stub_Subtype2TestCache_3135_x64_jit.txt`）と同じです。両方ともスタブの先頭から +0x10 で落ちています。
- **AOT の gdb の記録**: `aot_gdb_3135_futureor_cast_smi.txt`。同じ並びです。
- **呼び出し側の比較**:
  - `FutureOr<String>` の検査箇所には Smi の判定がありません（`callsite_check_FutureOrString_unoptimized.txt`）。
  - `FutureOr<num>` の検査箇所には `test al,1` の分岐があり、Smi はここで通されます（`callsite_check_FutureOrNum_unoptimized.txt`）。
- **クラス番号 0x39**: `class_id_0x39.txt`。
  - 3.47.7 の engine `deb287481e3c` が使う Dart は `04bcd1036cdc`（3.13.5）です。その `class_id.h` では、0x39（57）は `kClosureCid` です。
  - クラス番号はヘッダのビット 12 から 20 ビットにあります（`raw_object.h`、`assembler_x64.cc`）。
  - x64 の JIT と AOT は 8 バイトの `movq` で読んでいるので、圧縮ポインタは使っていません。
- **VM のフラグの表**: `flags_matrix_3135.txt`。次のどれを付けても落ちます。
  - `--optimization-counter-threshold=-1`
  - `--optimization-counter-threshold=1 --no-background-compilation`
  - `--no-background-compilation`
  - `--no-use-osr`
  - `--max-subtype-cache-entries=0`
  - `--enable-asserts`
  - `--no-eliminate-type-checks`
- **flutter_tester に VM のフラグを渡す方法**: flutter_tools の `flutter_tester_device.dart` が組み立てる起動の引数に、VM のフラグを渡す口はありません。単体の `dart` で再現できたので、そちらで調べました。
- **ソースの根拠**（取得したソースは `upstream-src/` にあります）:
  - `stub_code_compiler.cc` は、入力が 3 未満のとき `LoadClassId` を使います。コメントは「この経路に Smi は来ない」と前提しています。
  - 入力の数を決める `UsedInputsForType` は、型引数をすべて埋めた型（`FutureOr<String>` もこれ）に 2 を返します。
  - `FutureOr` には専用の型検査スタブが作られず、`DefaultTypeTest` から `SlowTypeTest` へ回ります。`SlowTypeTest` は Smi を判定しません。

## 版ごとの結果

表のファイルは `version_matrix_dart_run.txt`、`version_matrix_flutter_test.txt`、`flutter_logs/` です。

| Flutter | Dart | dart run (JIT) | flutter test（束ねた実行） | 別々のファイル |
|---|---|---|---|---|
| 3.38.7 | 3.10.7 | 落ちる | 落ちる | 通る |
| 3.47.2 | 3.13.2 | 落ちる | 落ちる | 通る |
| 3.47.4 | 3.13.3 | 落ちる | 落ちる | 通る |
| 3.47.5 | 3.13.4 | 落ちる | 落ちる | 通る |
| 3.47.7 | 3.13.5 | 落ちる | 落ちる | 通る |

AOT（`dart compile exe`）は 3.13.5 で 3 本とも落ちました。他の版の AOT は試していません。

## 既知かどうか

- **上流は制約を認識している**: commit ffddb2231f0d（2026-07-20、「[modular_aot] Fix TypeTest to reject Smis before calling STC」）に「SubtypeTestCache stubs do not support Smis for n < 3」とあります。ただし直したのは新しい modular AOT（`pkg/native_compiler`）だけです。
- **main でも未修正のまま**: 2026-10-16 時点の main（3.15.0 の開発版）のソースでは、該当する分岐は変わっていません。`SlowTypeTest` にも Smi の判定はありません。ソースを読んだだけで、main は動かしていません。
- **似た issue**: この症状の issue は見つかりませんでした。dart-lang/sdk#63413 も Smi が絡む SIGSEGV ですが、原因は最適化の LICM で、別の不具合です。
- **関連しそうな報告（推測）**: [flutter/flutter#162375](https://github.com/flutter/flutter/issues/162375)（iOS のリリース版、open、P2）がこの不具合である可能性があります。
  - 報告では `Future<String>` の async 関数の中の `return await json.decode(result);` で、`KERN_INVALID_ADDRESS 0xffffffffffffffff` で落ちています。
  - 報告者は返す前に `is String` を確かめる形にして回避しています。
  - 同じ形を x64 で再現すると（JSON の文字列の後に `"0"`）、JIT でも AOT でも同じ番地 `0xffffffffffffffff` で落ちました。arm64 では確かめていません。

## 影響の範囲

- **テスト・debug 実行（JIT）**: 確実に起きます。1 つの isolate の中で、同じ検査箇所を String が通った後に失敗する Smi が来れば落ちます。束ねた実行は必須ではありません。1 つのファイルに 2 本並べても落ちます。
- **本番（AOT）**: x64 の `dart compile exe` で起きることを確かめました。スタブの生成コードは CPU の種類によらず共通なので、arm64 の Android / iOS のリリース版でも起こりうると考えます（推測、実機では未確認）。起きると、本来なら捕まえられる `TypeError` がプロセス全体のクラッシュになります。
- **起きない場合**:
  - 検査が成功する値（例: `Future<num>` に `42`）
  - `FutureOr` 以外の型への検査
  - 最初に来る Smi

## 未確認のこと

- main / dev / beta の SDK で直っているか（ソース上は未修正に見えます）
- arm64 と圧縮ポインタありの環境での実際の挙動
- いつから入った不具合か（3.10.7 では起きます）
- 修正案を実際にビルドして試すこと

新しい SDK で確かめるには、次のダウンロードが要ります。取得していません。

- Dart SDK の dev 版または main 版の linux-x64 release の zip。取得元は `https://storage.googleapis.com/dart-archive/channels/{dev|main}/release/latest/sdk/dartsdk-linux-x64-release.zip` で、大きさはおよそ 200〜300MB です。
- Flutter の master / beta を使う場合は、engine の成果物も含めて数 GB になります。

## 作業中に外へ出た影響

- **git fetch を 1 回実行**: 作業用リポジトリで `git fetch dayseum develop` を実行し、リモートの追跡用 ref が更新されました。作業ツリーとブランチは変えていません。
- **コアダンプが溜まった**: 再現を繰り返したので、`/var/lib/systemd/coredump` に約 80 件が溜まっています（ディレクトリ全体で 2.2GB、`/` の空きは 15GB）。消していません。
- **会社のソースの展開先**: `/mnt/ct1/idd/dart-vm-survey/src` に展開したままです。変えたファイルは元に戻しました。

---

## dart-lang/sdk への報告の下書き（英語）

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