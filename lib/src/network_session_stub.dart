import 'dart:typed_data';

import 'network_models.dart';

class OronboxNetworkSession {
  OronboxNetworkSession._();

  static Future<OronboxNetworkSession> open({
    OronboxNetworkConfig config = const OronboxNetworkConfig(),
  }) =>
      throw UnsupportedError('OronBox Network is unavailable on this platform');

  Stream<OronboxNetworkEvent> get events => const Stream.empty();
  Stream<Uint8List> get outboundPackets => const Stream.empty();
  void pushInbound(Uint8List packet) => throw StateError('Session is closed');
  OronboxNetworkSnapshot get snapshot => throw StateError('Session is closed');
  Future<void> close() async {}
}
