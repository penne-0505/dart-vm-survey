// async Future<String>: two calls of String only, then Smi
Future<String> f(dynamic x) async => x;
Future<void> main() async {
  print(await f('a'));
  print(await f('b'));
  try { print(await f(42)); } catch (e) { print('caught: $e'); }
}
