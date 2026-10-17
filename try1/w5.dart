// async Future<double>: warm with double, then Smi
Future<double> f(dynamic x) async => x;
Future<void> main() async {
  print(await f(1.5));
  try { print(await f(42)); } catch (e) { print('caught: $e'); }
}
