// The pattern from flutter/flutter#162375: `return await json.decode(...)`
// in an async function returning Future<String>. One stored value is a JSON
// string, another is the JSON number 0.
import 'dart:convert';

Future<String> get(String stored, String defaultValue) async {
  try {
    return await json.decode(stored);
  } catch (e) {
    print('caught: ${e.runtimeType}');
    return defaultValue;
  }
}

Future<void> main() async {
  print(await get('"hello"', 'default')); // a JSON string: passes
  print(await get('0', 'default')); // expected: caught: TypeError, default
}
