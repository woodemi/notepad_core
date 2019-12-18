@JS()
library notepad_core_js;

import 'dart:html';

import 'package:js/js.dart';

@JS('navigator.bluetooth')
class Bluetooth {
  external static dynamic requestDevice(ScanOptions options);
}

@JS()
@anonymous
class ScanOptions {
  external set acceptAllDevices(bool v);

  external factory ScanOptions({
    bool acceptAllDevices,
  });
}

@JS()
mixin BluetoothDevice implements EventTarget {
  /// Event type should be [const]
  static const String disconnectEvent = 'gattserverdisconnected';

  external String get id;

  external String get name;

  external BluetoothRemoteGATTServer get gatt;
}

@JS()
class BluetoothRemoteGATTServer {
  external BluetoothDevice get device;

  external bool get connected;

  external dynamic connect();

  external void disconnect();
}