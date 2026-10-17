// closure async with await
Future<String> Function() g(dynamic x) => () async {
  await null;
  return x;
};
Future<void> main() async {
  print(await g('s')());
  try { print(await g(42)()); } catch (e) { print('caught: $e'); }
}
