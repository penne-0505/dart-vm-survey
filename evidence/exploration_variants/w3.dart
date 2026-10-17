import 'dart:async';
// `is FutureOr<String>`
bool f(dynamic x) => x is FutureOr<String>;
void main() {
  print(f('s'));
  print(f(42));
}
