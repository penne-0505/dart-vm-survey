// Minimal reproduction: a failing `as FutureOr<T>` check on a Smi crashes
// the VM (SIGSEGV) once the check's SubtypeTestCache has an entry.
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
  check('a'); // passes; the check site's SubtypeTestCache gets an entry
  check(42); // expected: TypeError. actual: SIGSEGV (si_addr = 0x53)
}
