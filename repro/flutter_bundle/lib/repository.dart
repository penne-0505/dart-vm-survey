/// Stand-in for a repository that reads an id out of a decoded JSON body.
///
/// `body['picture_id']` is `dynamic`; returning it from an `async` function
/// whose declared type is `Future<String>` makes the VM check the value
/// against `FutureOr<String>` at run time.
Future<String> readPictureId(Future<Map<String, dynamic>> response) async {
  final Map<String, dynamic> body = await response;
  return body['picture_id'];
}
