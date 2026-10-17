import 'package:flutter_test/flutter_test.dart';
import 'package:futureor_smi_repro/repository.dart';

void main() {
  test('placeholder', () {});
  test('an int id is rejected with a TypeError', () async {
    await expectLater(
      readPictureId(Future.value({'picture_id': 42})),
      throwsA(isA<TypeError>()),
    );
  });
}
