import 'dart:async';
void check(Object? x) {
  try { x as FutureOr<double>; print('ok: $x'); } on TypeError catch (e) { print('TypeError'); }
}
void main() { check(1.5); check(42); }
