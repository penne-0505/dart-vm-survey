// Control: the same sequence against a non-FutureOr type works.
void check(Object? x) {
  try {
    x as String;
    print('ok: $x');
  } on TypeError catch (e) {
    print('TypeError: $e');
  }
}

void main() {
  check('a');
  check(42);
}
