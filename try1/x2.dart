// valid program: Future<int>, Mint then Smi
Future<int> f(dynamic x) async => x;
Future<void> main() async {
  print(await f(1 << 62));
  print(await f(42));
}
