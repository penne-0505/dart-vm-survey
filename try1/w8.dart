// async Future<String?>: warm with String, then Smi
Future<String?> f(dynamic x) async => x;
Future<void> main() async {
  print(await f('a'));
  try { print(await f(42)); } catch (e) { print('caught: $e'); }
}
