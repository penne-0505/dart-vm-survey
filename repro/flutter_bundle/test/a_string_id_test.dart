import 'package:flutter_test/flutter_test.dart';
import 'package:futureor_smi_repro/repository.dart';

void main() {
  test('a String id passes the check', () async {
    expect(await readPictureId(Future.value({'picture_id': 'picture-1'})),
        'picture-1');
  });
}
