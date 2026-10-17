// top-level async, no await, dynamic -> String return
Future<String> f(dynamic x) async {
  return x;
}
Future<void> main() async {
  print(await f('s'));
  try { print(await f(42)); } catch (e) { print('caught: $e'); }
}
