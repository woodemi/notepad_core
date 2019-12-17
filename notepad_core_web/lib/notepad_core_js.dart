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
  external String get id;

  external String get name;

  external BluetoothRemoteGATTServer get gatt;
}

@JS()
class BluetoothRemoteGATTServer {
  external dynamic connect();

  external void disconnect();
}