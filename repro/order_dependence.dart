// Order dependence: the first Smi is rejected with the expected TypeError
// (the cache is still empty); after a String passes, the next Smi crashes.
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
  check(42); // TypeError (expected)
  check('a'); // ok
  check(43); // expected: TypeError. actual: SIGSEGV (si_addr = 0x55)
}
