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