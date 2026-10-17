// Runs both files in one isolate, as test bundlers (e.g. very_good_cli's
// --optimization) do.
import 'package:flutter_test/flutter_test.dart';

import 'a_string_id_test.dart' as a;
import 'b_int_id_test.dart' as b;

void main() {
  group('a', a.main);
  group('b', b.main);
}
