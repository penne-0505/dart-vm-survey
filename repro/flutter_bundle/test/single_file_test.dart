// The same two tests in one file also crash: the bug does not need
// bundling, only a String check before an int check in one isolate.
import 'package:flutter_test/flutter_test.dart';
import 'package:futureor_smi_repro/repository.dart';

void main() {
  test('a String id passes the check', () async {
    expect(await readPictureId(Future.value({'picture_id': 'picture-1'})),
        'picture-1');
  });
  test('an int id is rejected with a TypeError', () async {
    await expectLater(
      readPictureId(Future.value({'picture_id': 42})),
      throwsA(isA<TypeError>()),
    );
  });
}
