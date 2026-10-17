// top-level async with await before return
Future<String> f(dynamic x) async {
  await null;
  return x;
}
Future<void> main() async {
  print(await f('s'));
  try { print(await f(42)); } catch (e) { print('caught: $e'); }
}
