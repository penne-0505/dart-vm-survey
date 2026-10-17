import 'dart:async';
void check(Object? x) {
  try { x as FutureOr<num>; print('ok: $x'); } on TypeError catch (e) { print('TypeError: $e'); }
}
void main() { check(1.5); check(42); check('s'); check(43); }
