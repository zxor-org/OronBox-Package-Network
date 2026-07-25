import 'dart:typed_data';

const oronboxNetworkAbiVersion = 1;

class OronboxNetworkConfig {
  const OronboxNetworkConfig({
    this.mtu = 800,
    this.ingressCapacity = 256,
    this.stackCapacity = 256,
    this.outboundCapacity = 128,
    this.meterWindowSeconds = 5,
    this.statsIntervalMilliseconds = 1000,
    this.capturePath,
  });

  final int mtu;
  final int ingressCapacity;
  final int stackCapacity;
  final int outboundCapacity;
  final int meterWindowSeconds;
  final int statsIntervalMilliseconds;
  final String? capturePath;
}

enum OronboxNetworkEventType { packet, state, statistics, warning, closed }

sealed class OronboxNetworkEvent {
  const OronboxNetworkEvent(this.type);
  final OronboxNetworkEventType type;
}

class OronboxNetworkPacket extends OronboxNetworkEvent {
  const OronboxNetworkPacket(this.bytes)
    : super(OronboxNetworkEventType.packet);
  final Uint8List bytes;
}

class OronboxNetworkStatus extends OronboxNetworkEvent {
  const OronboxNetworkStatus(this.message)
    : super(OronboxNetworkEventType.state);
  final String message;
}

class OronboxNetworkStatistics extends OronboxNetworkEvent {
  const OronboxNetworkStatistics({
    required this.bytesFromDevice,
    required this.bytesToDevice,
    required this.readBytesPerSecond,
    required this.writeBytesPerSecond,
    required this.activeSessions,
    required this.droppedPackets,
  }) : super(OronboxNetworkEventType.statistics);

  final int bytesFromDevice;
  final int bytesToDevice;
  final double readBytesPerSecond;
  final double writeBytesPerSecond;
  final int activeSessions;
  final int droppedPackets;
}

class OronboxNetworkWarning extends OronboxNetworkEvent {
  const OronboxNetworkWarning(this.message)
    : super(OronboxNetworkEventType.warning);
  final String message;
}

class OronboxNetworkClosed extends OronboxNetworkEvent {
  const OronboxNetworkClosed() : super(OronboxNetworkEventType.closed);
}

class OronboxNetworkSnapshot {
  const OronboxNetworkSnapshot({
    required this.bytesFromDevice,
    required this.bytesToDevice,
    required this.activeSessions,
    required this.droppedPackets,
  });

  final int bytesFromDevice;
  final int bytesToDevice;
  final int activeSessions;
  final int droppedPackets;
}
