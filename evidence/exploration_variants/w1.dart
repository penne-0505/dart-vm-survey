import 'dart:async';
// sync implicit cast to FutureOr<String>
FutureOr<String> f(dynamic x) => x;
void main() {
  print(f('s'));
  try { print(f(42)); } catch (e) { print('caught: $e'); }
}
