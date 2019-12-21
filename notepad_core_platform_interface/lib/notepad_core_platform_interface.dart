library notepad_core_platform_interface;

import 'dart:async';
import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel_notepad_core.dart';
import 'models.dart';

export 'models.dart';

/// FIXME `import 'package:tuple/tuple.dart';` fails
class Tuple2<T1, T2> {
  /// Returns the first item of the tuple
  final T1 item1;

  /// Returns the second item of the tuple
  final T2 item2;

  /// Creates a new tuple value with the specified items.
  const Tuple2(this.item1, this.item2);
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

  Future<bool> isBluetoothAvailable();

  Future<dynamic> requestDevice({
    List<String> optionalServices,
  });

  void startScan();

  void stopScan();

  Stream<dynamic> get scanResultStream;

  void connect(scanResult);

  void disconnect();

  MessageHandler messageHandler;

  Future<void> setNotifiable(Tuple2<String, String> serviceCharacteristic);

  void readValue(Tuple2<String, String> serviceCharacteristic);

  Future<void> writeValue(Tuple2<String, String> serviceCharacteristic, Uint8List value);

  Stream<Tuple2<String, Uint8List>> get inputValueStream;
}
