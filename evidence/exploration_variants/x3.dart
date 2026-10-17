// valid program: Future<Object>, String then int
Future<Object> f(dynamic x) async => x;
Future<void> main() async {
  print(await f('s'));
  print(await f(42));
}
