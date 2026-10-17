import 'dart:async';
void check(Object? x) {
  try { x as Future<String>; print('ok: $x'); } on TypeError catch (e) { print('TypeError'); }
}
void main() { check(Future.value("s")); check(42); }
