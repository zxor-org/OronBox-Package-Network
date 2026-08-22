import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'network_bindings.dart';
import 'network_models.dart';

const _noEvent = 1;

final class _WakeDispatcher {
  _WakeDispatcher._() {
    _callback = NativeCallable<ZbWakeNative>.listener(_onWake);
  }

  static final instance = _WakeDispatcher._();

  late final NativeCallable<ZbWakeNative> _callback;
  final Map<int, OronboxNetworkSession> _sessions = {};

  Pointer<NativeFunction<ZbWakeNative>> get nativeFunction =>
      _callback.nativeFunction;

  void register(OronboxNetworkSession session) {
    _sessions[session._handle] = session;
  }

  void unregister(OronboxNetworkSession session) {
    if (identical(_sessions[session._handle], session)) {
      _sessions.remove(session._handle);
    }
  }

  void _onWake(int handle) {
    _sessions[handle]?._scheduleDrain();
  }
}

class OronboxNetworkSession {
  OronboxNetworkSession._(this._bindings, this._handle);

  static Future<OronboxNetworkSession> open({
    OronboxNetworkConfig config = const OronboxNetworkConfig(),
  }) async {
    final bindings = OronboxNetworkBindings.load();
    final nativeAbi = bindings.abiVersion();
    if (nativeAbi != oronboxNetworkAbiVersion) {
      throw StateError(
        'OronBox Network ABI mismatch: Dart $oronboxNetworkAbiVersion, native $nativeAbi',
      );
    }

    final dispatcher = _WakeDispatcher.instance;
    final nativeConfig = calloc<ZbNetworkConfigNative>();
    final outHandle = calloc<Uint64>();
    final capturePath = config.capturePath?.toNativeUtf8();
    try {
      nativeConfig.ref
        ..abiVersion = oronboxNetworkAbiVersion
        ..mtu = config.mtu
        ..reserved = 0
        ..ingressCapacity = config.ingressCapacity
        ..stackCapacity = config.stackCapacity
        ..outboundCapacity = config.outboundCapacity
        ..meterWindowMilliseconds = config.meterWindowSeconds * 1000
        ..statisticsIntervalMilliseconds = config.statsIntervalMilliseconds
        ..capturePath = capturePath ?? nullptr;
      final status = bindings.open(
        nativeConfig,
        dispatcher.nativeFunction,
        outHandle,
      );
      if (status != 0) {
        throw StateError(bindings.errorMessage());
      }
      final session = OronboxNetworkSession._(bindings, outHandle.value);
      dispatcher.register(session);
      session._scheduleDrain();
      return session;
    } finally {
      if (capturePath != null) calloc.free(capturePath);
      calloc.free(outHandle);
      calloc.free(nativeConfig);
    }
  }

  final OronboxNetworkBindings _bindings;
  final int _handle;
  final _events = StreamController<OronboxNetworkEvent>.broadcast(sync: true);
  final _outboundPackets = StreamController<Uint8List>.broadcast(sync: true);

  bool _closed = false;
  bool _drainScheduled = false;

  Stream<OronboxNetworkEvent> get events => _events.stream;
  Stream<Uint8List> get outboundPackets => _outboundPackets.stream;

  void pushInbound(Uint8List packet) {
    _ensureOpen();
    final pointer = calloc<Uint8>(packet.length);
    try {
      pointer.asTypedList(packet.length).setAll(0, packet);
      _check(_bindings.push(_handle, pointer, packet.length));
    } finally {
      calloc.free(pointer);
    }
  }

  OronboxNetworkSnapshot get snapshot {
    _ensureOpen();
    final native = calloc<ZbNetworkSnapshotNative>();
    try {
      _check(_bindings.snapshot(_handle, native));
      return OronboxNetworkSnapshot(
        bytesFromDevice: native.ref.bytesFromDevice,
        bytesToDevice: native.ref.bytesToDevice,
        activeSessions: native.ref.activeSessions,
        droppedPackets: native.ref.droppedPackets,
      );
    } finally {
      calloc.free(native);
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    final status = _bindings.close(_handle);
    _WakeDispatcher.instance.unregister(this);
    if (!_events.isClosed) {
      _events.add(const OronboxNetworkClosed());
    }
    await Future.wait([_events.close(), _outboundPackets.close()]);
    if (status != 0) {
      throw StateError(_bindings.errorMessage());
    }
  }

  void _scheduleDrain() {
    if (_closed || _drainScheduled) return;
    _drainScheduled = true;
    scheduleMicrotask(() {
      _drainScheduled = false;
      if (_closed) return;
      try {
        _drain();
      } catch (error, stackTrace) {
        if (!_events.isClosed) _events.addError(error, stackTrace);
      }
    });
  }

  void _drain() {
    final kind = calloc<Uint32>();
    final length = calloc<Size>();
    try {
      while (!_closed) {
        final peekStatus = _bindings.eventPeek(_handle, kind, length);
        if (peekStatus == _noEvent) return;
        _check(peekStatus);
        final buffer = length.value == 0
            ? nullptr.cast<Uint8>()
            : calloc<Uint8>(length.value);
        try {
          _check(
            _bindings.eventRead(_handle, buffer, length.value, kind, length),
          );
          final payload = length.value == 0
              ? Uint8List(0)
              : Uint8List.fromList(buffer.asTypedList(length.value));
          _emit(_decodeEvent(kind.value, payload));
        } finally {
          if (buffer != nullptr) calloc.free(buffer);
        }
      }
    } finally {
      calloc.free(length);
      calloc.free(kind);
    }
  }

  OronboxNetworkEvent _decodeEvent(int kind, Uint8List payload) {
    switch (kind) {
      case 1:
        return OronboxNetworkPacket(payload);
      case 2:
        return OronboxNetworkStatus(utf8.decode(payload));
      case 3:
        final value = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
        return OronboxNetworkStatistics(
          bytesFromDevice: value['bytes_from_device'] as int,
          bytesToDevice: value['bytes_to_device'] as int,
          readBytesPerSecond: (value['read_bytes_per_second'] as num)
              .toDouble(),
          writeBytesPerSecond: (value['write_bytes_per_second'] as num)
              .toDouble(),
          activeSessions: value['active_sessions'] as int,
          droppedPackets: value['dropped_packets'] as int,
        );
      case 4:
        return OronboxNetworkWarning(utf8.decode(payload));
      default:
        return OronboxNetworkWarning('Unknown native event kind $kind');
    }
  }

  void _emit(OronboxNetworkEvent event) {
    if (_events.isClosed) return;
    _events.add(event);
    if (event case OronboxNetworkPacket(:final bytes)) {
      _outboundPackets.add(bytes);
    }
  }

  void _check(int status) {
    if (status != 0) throw StateError(_bindings.errorMessage());
  }

  void _ensureOpen() {
    if (_closed) throw StateError('OronBox Network session is closed');
  }
}
