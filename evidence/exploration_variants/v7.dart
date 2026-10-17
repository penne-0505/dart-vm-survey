// sync function, implicit cast
String f(dynamic x) {
  return x;
}
void main() {
  print(f('s'));
  try { print(f(42)); } catch (e) { print('caught: $e'); }
}
