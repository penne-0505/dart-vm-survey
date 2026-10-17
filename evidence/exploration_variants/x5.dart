// Future<int>: Smi first then Smi
Future<int> f(dynamic x) async => x;
Future<void> main() async {
  print(await f(1));
  print(await f(42));
  print(await f(1 << 62));
  print(await f(43));
}
