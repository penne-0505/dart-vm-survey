// Same bug after the check site has been optimized by the JIT:
// warm the check with many Strings, then pass a Smi.
import 'dart:async';

@pragma('vm:never-inline')
Object? cast(Object? x) => x as FutureOr<String>;

void main() {
  var n = 0;
  for (var i = 0; i < 200000; i++) {
    if (cast('a') != null) n++;
  }
  print('warmed: $n');
  try {
    cast(42);
    print('no error');
  } on TypeError catch (e) {
    print('TypeError: $e'); // expected
  }
}
