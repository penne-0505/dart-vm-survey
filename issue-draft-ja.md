# dart-lang/sdk に出す issue の下書き（日本語・温度感の確認用）

※ 英語にするときはこの構成のまま訳す。原文の中の `<!-- -->` は投稿に含めない注記。

---

**題名**

[vm] Smi に対する失敗する `as FutureOr<T>` が、TypeError ではなく SIGSEGV で落ちる（JIT / AOT）

**本文**

同じ箇所の `as FutureOr<T>` を先にヒープのオブジェクトが通ったあと、Smi（`T` の部分型でない `int`）が通ると、`TypeError` にならず VM が SIGSEGV で落ちます。

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

期待: 2 回目の呼び出しで `TypeError` が表示される。
実際: `ok: a` の後に VM が落ちる。

```
si_signo=Segmentation fault(11), si_code=SEGV_MAPERR(1), si_addr=0x53
  pc 0x00007f9ab2a05240 fp 0x00007f9ab1dfe338 [Stub] Subtype2TestCache+0x10
  pc 0x00007f9ab2a2d075 fp 0x00007f9ab1dfe380 [Unoptimized] check+0xa5
```

<details><summary>クラッシュの出力（全文）</summary>

```
<!-- dev の `dart run` の出力をそのまま貼る -->
```

</details>

- `dart run` と `dart compile exe` のどちらでも落ちます。
- 確認した版（すべて linux_x64）: 3.10.7、3.13.2〜3.13.5（stable）、3.14.0-315.1.beta、3.15.0-27.0.dev
- `check('a')` を先に呼ばなければ、`TypeError` になります。
- `x as String`（`FutureOr` でない型）なら、`TypeError` になります。
- `si_addr` は渡した整数の値で変わります（`0` → `0xffffffffffffffff`、`42` → `0x53`、`1 << 40` → `0x1ffffffffff`）。
- 実際のアプリでは、`async` 関数で `Future<String>` を返すとき、JSON から取った値をそのまま返す形で起きました。`return json['id'];` で `id` が数値の場合です。

flutter/flutter#162375 の iOS AOT のクラッシュ（`Subtype2TestCache` ← `SlowTypeTest`）は、これと同じ原因だと思います。

再現の切り出しと調査には AI アシスタント（Claude）を使いました。上の結果は、挙げた版で自分で実行して確かめています。
