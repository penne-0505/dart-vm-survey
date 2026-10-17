// explicit cast in async function
Future<String> f(dynamic x) async {
  await null;
  return x as String;
}
Future<void> main() async {
  print(await f('s'));
  try { print(await f(42)); } catch (e) { print('caught: $e'); }
}
