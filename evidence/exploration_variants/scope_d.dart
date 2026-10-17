import 'dart:async';
void check(Object? x) {
  try { x as Comparable<String>; print('ok: $x'); } on TypeError catch (e) { print('TypeError'); }
}
void main() { check("s"); check(42); }
