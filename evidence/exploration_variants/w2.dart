import 'dart:async';
// explicit `as FutureOr<String>`
Object? f(dynamic x) => x as FutureOr<String>;
void main() {
  print(f('s'));
  try { print(f(42)); } catch (e) { print('caught: $e'); }
}
