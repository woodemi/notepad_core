library notepad_core_platform_interface;

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel_notepad_core.dart';

typedef MessageHandler = Future<dynamic> Function(NotepadCoreMessage message);

class NotepadCoreMessage {
  const NotepadCoreMessage._();
}

abstract class NotepadCorePlatform extends PlatformInterface {
  NotepadCorePlatform() : super(token: _token);

  static final Object _token = Object();

  static NotepadCorePlatform _instance = MethodChannelNotepadCore();

  static NotepadCorePlatform get instance => _instance;

  static set instance(NotepadCorePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<dynamic> requestDevice();

  void startScan();

  void stopScan();

  Stream<dynamic> get scanResultStream;

  void connect(scanResult);

  void disconnect();

  MessageHandler messageHandler;
}

class ConnectionState extends NotepadCoreMessage {
  static const disconnected = ConnectionState._('disconnected');
  static const connecting = ConnectionState._('connecting');
  static const connected = ConnectionState._('connected');

  final String value;

  const ConnectionState._(this.value) : super._();

  static ConnectionState parse(String value) {
    if (value == disconnected.value) {
      return disconnected;
    } else if (value == connecting.value) {
      return connecting;
    } else if (value == connected.value) {
      return connected;
    }
    throw ArgumentError.value(value);
  }
}