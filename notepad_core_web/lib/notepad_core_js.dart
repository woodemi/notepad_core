@JS()
library notepad_core_js;

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
class BluetoothDevice {
  static final String disconnectEvent = 'gattserverdisconnected';
  
  external String get id;

  external String get name;

  external BluetoothRemoteGATTServer get gatt;

  external void addEventListener(String type, listener(dynamic event), [bool useCapture]);

  external void removeEventListener(String type, listener(dynamic event), [bool useCapture]);
}

@JS()
class BluetoothRemoteGATTServer {
  external BluetoothDevice get device;

  external bool get connected;

  external dynamic connect();

  external void disconnect();
}