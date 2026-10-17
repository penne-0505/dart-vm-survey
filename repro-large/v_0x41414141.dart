import 'dart:async';
void check(Object? x) {
  try { x as FutureOr<String>; print('ok: $x'); }
  on TypeError catch (e) { print('TypeError: $e'); }
}
void main() { check('a'); check(0x41414141); }
