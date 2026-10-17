// async, String then double (heap, non-Smi)
Future<String> f(dynamic x) async => x;
Future<void> main() async {
  print(await f('s'));
  try { print(await f(4.2)); } catch (e) { print('caught: $e'); }
  try { print(await f(42)); } catch (e) { print('caught: $e'); }
}
