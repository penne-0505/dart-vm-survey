import 'dart:async';
void check(Object? x) {
  try { x as FutureOr<List<int>>; print('ok: $x'); } on TypeError catch (e) { print('TypeError'); }
}
void main() { check(<int>[1]); check(42); }
