import 'dart:async';
// sync FutureOr<num> valid
FutureOr<num> f(dynamic x) => x;
void main() {
  print(f(1.5));
  print(f(42));
}
