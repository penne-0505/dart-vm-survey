// async Future<String>: warm with int first (fails), then String, then int
Future<String> f(dynamic x) async => x;
Future<void> main() async {
  try { print(await f(41)); } catch (e) { print('caught: $e'); }
  print(await f('a'));
  try { print(await f(42)); } catch (e) { print('caught: $e'); }
}
