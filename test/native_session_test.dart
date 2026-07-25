import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oronbox_network/oronbox_network.dart';

void main() {
  test(
    'opens the native library through Dart FFI',
    () async {
      final session = await OronboxNetworkSession.open();
      expect(session.snapshot.bytesFromDevice, 0);
      expect(session.snapshot.bytesToDevice, 0);
      await session.close();
    },
    skip: Platform.environment['ORONBOX_NETWORK_NATIVE_TEST'] != '1',
  );
}
