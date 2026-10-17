// only the int call (no String warm-up)
Future<String> f(dynamic x) async {
  await null;
  return x;
}
Future<void> main() async {
  try { print(await f(42)); } catch (e) { print('caught: $e'); }
}
