I think this is the same crash as dart-lang/sdk#64620, which has a minimal Dart-only repro (JIT and AOT, still crashing on 3.15.0-27.0.dev).

The VM crashes in `Subtype2TestCache` (called from `SlowTypeTest`) when an `int` reaches an `as FutureOr<T>` check that a heap object has already passed. This matches the symbolized stack posted above (`Subtype2TestCache + 8` ← `SlowTypeTest + 176`). An `int` 0 gives the same fault address, `0xffffffffffffffff`.

In app code this can happen when an `async` function returning `Future<T>` returns a decoded JSON value that turns out to be an `int`. A workaround until it's fixed is to cast explicitly before returning, e.g. `return json.decode(result) as T;`. A mismatch then throws a `TypeError` instead of crashing.
