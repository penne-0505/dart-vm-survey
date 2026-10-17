// Same bug reached through the implicit return check of an async function:
// `return <dynamic>` in an `async` function returning Future<String> checks
// the value against FutureOr<String>.
Future<String> pictureId(Map<String, dynamic> body) async {
  return body['picture_id'];
}

Future<void> main() async {
  print(await pictureId({'picture_id': 'picture-1'}));
  try {
    print(await pictureId({'picture_id': 42}));
  } on TypeError catch (e) {
    print('TypeError: $e'); // expected
  }
}
