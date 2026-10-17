// async Future<List<int>>: warm with list, then Smi
Future<List<int>> f(dynamic x) async => x;
Future<void> main() async {
  print(await f(<int>[1]));
  try { print(await f(42)); } catch (e) { print('caught: $e'); }
}
