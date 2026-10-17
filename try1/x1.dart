// valid program: Future<num>, double then int
Future<num> f(dynamic x) async => x;
Future<void> main() async {
  print(await f(1.5));
  print(await f(42));
}
