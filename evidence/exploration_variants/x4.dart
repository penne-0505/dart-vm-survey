// as List<int> warmed then Smi
Object? f(dynamic x) => x as List<int>;
void main() {
  print(f(<int>[1]));
  try { print(f(42)); } catch (e) { print('caught: $e'); }
}
