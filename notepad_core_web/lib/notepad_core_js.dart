@JS()
library notepad_core_js;

import 'dart:html' show EventTarget;

import 'package:js/js.dart';
import 'package:js/js_util.dart' show getProperty, callMethod;

import 'js_facade.dart';

@JS('navigator.bluetooth')
class Bluetooth {
  external static Promise<dynamic> requestDevice(ScanOptions options);
}

@JS()
@anonymous
class ScanOptions {
  external set acceptAllDevices(bool v);

  external factory ScanOptions({
    bool acceptAllDevices,
  });
}

class BluetoothDevice extends EventTargetDelegate {
  /// Event type should be [const]
  static const String disconnectEvent = 'gattserverdisconnected';

  final EventTarget _delegate;

  BluetoothDevice(this._delegate) {
    _gatt = BluetoothRemoteGATTServer(getProperty(_delegate, 'gatt'), this);
  }

  @override
  EventTarget get eventTarget => _delegate;

  String get id => getProperty(_delegate, 'id');

  String get name => getProperty(_delegate, 'name');

  BluetoothRemoteGATTServer _gatt;

  BluetoothRemoteGATTServer get gatt => _gatt;
}

class BluetoothRemoteGATTServer {
  final dynamic _delegate;

  BluetoothRemoteGATTServer(this._delegate, this._device);

  final BluetoothDevice _device;

  BluetoothDevice get device => _device;

  bool get connected => getProperty(_delegate, 'connected');

  Promise<dynamic> connect() => callMethod(_delegate, 'connect', null);

  void disconnect() => callMethod(_delegate, 'disconnect', null);
}