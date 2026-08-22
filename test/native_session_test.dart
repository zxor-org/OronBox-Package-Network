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

  test(
    'reuses the isolate callback across rapid session shutdowns',
    () async {
      for (var index = 0; index < 100; index++) {
        final session = await OronboxNetworkSession.open();
        await session.close();
      }
      await Future<void>.delayed(Duration.zero);
    },
    skip: Platform.environment['ORONBOX_NETWORK_NATIVE_TEST'] != '1',
  );

  test(
    'closing one session does not stop another session callback',
    () async {
      final first = await OronboxNetworkSession.open();
      final second = await OronboxNetworkSession.open();
      await first.close();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(second.snapshot.activeSessions, 0);
      await second.close();
    },
    skip: Platform.environment['ORONBOX_NETWORK_NATIVE_TEST'] != '1',
  );
}
