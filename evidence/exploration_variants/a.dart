import 'dart:async';

Future<String> run(Map<String, dynamic> body) async {
  return body['picture_id'];
}

Future<R> tryCatch<R>(Future<R> Function() f) async {
  try {
    return await f();
  } catch (e) {
    print('caught: ${e.runtimeType}: $e');
    rethrow;
  }
}

Future<String> gen(Map<String, dynamic> body) => tryCatch(() async {
      final Map<String, dynamic> responseBody = await Future.value(body);
      return responseBody['picture_id'];
    });

Future<void> main() async {
  print(await gen({'picture_id': 'picture-1'}));
  try {
    print(await gen({'picture_id': 42}));
  } catch (e) {
    print('outer: $e');
  }
  try {
    print(await run({'picture_id': 42}));
  } catch (e) {
    print('outer2: $e');
  }
}
