@JS()
library notepad_core_js;

import 'dart:html' show EventTarget;
import 'dart:typed_data';

import 'package:js/js.dart';

import 'js_facade.dart';

@JS('navigator.bluetooth')
class Bluetooth {
  external static Promise<dynamic> requestDevice(ScanOptions options);
}

@JS()
@anonymous
class ScanOptions {
  external set optionalServices(List<dynamic> list);

  external set acceptAllDevices(bool v);

  external factory ScanOptions({
    List<dynamic> optionalServices,
    bool acceptAllDevices,
  });
}

class BluetoothDevice extends EventTargetDelegate {
  /// Event type should be [const]
  static const String disconnectEvent = 'gattserverdisconnected';

  BluetoothDevice(EventTarget delegate): super(delegate) {
    _gatt = BluetoothRemoteGATTServer(getProperty('gatt'), this);
  }

  String get id => getProperty('id');

  String get name => getProperty('name');

  BluetoothRemoteGATTServer _gatt;

  BluetoothRemoteGATTServer get gatt => _gatt;
}

class BluetoothRemoteGATTServer extends Delegate<dynamic> {
  BluetoothRemoteGATTServer(dynamic delegate, this._device): super(delegate);

  final BluetoothDevice _device;

  BluetoothDevice get device => _device;

  bool get connected => getProperty('connected');

  Future<BluetoothRemoteGATTServer> connect() {
    var promise = callMethod('connect', null);
    return promiseToFuture(promise).then((_) => this);
  }

  void disconnect() => callMethod('disconnect', null);

  Future<BluetoothRemoteGATTService> getPrimaryService(dynamic bluetoothUuid) {
    var promise = callMethod('getPrimaryService', [bluetoothUuid]);
    return promiseToFuture(promise).then((result) => BluetoothRemoteGATTService(result));
  }
}

@JS('BluetoothUUID.getService')
external dynamic getServiceUUID(String name);

@JS('BluetoothUUID.getCharacteristic')
external dynamic getCharacteristicUUID(String name);

class BluetoothRemoteGATTService extends Delegate<dynamic> {
  BluetoothRemoteGATTService(dynamic delegate): super(delegate);

  Future<BluetoothRemoteGATTCharacteristic> getCharacteristic(dynamic bluetoothUuid) {
    var promise = callMethod('getCharacteristic', [bluetoothUuid]);
    return promiseToFuture(promise).then((result) => BluetoothRemoteGATTCharacteristic(result));
  }
}

class BluetoothRemoteGATTCharacteristic extends EventTargetDelegate {
  static const valueChangedEvent = 'characteristicvaluechanged';

  BluetoothRemoteGATTCharacteristic(EventTarget delegate): super(delegate);

  String get uuid => getProperty('uuid');

  Uint8List get value => (getProperty('value') as ByteData).buffer.asUint8List();

  Future<dynamic> writeValue(Uint8List bytes) {
    var promise = callMethod('writeValue', [bytes]);
    return promiseToFuture(promise);
  }

  Future<dynamic> startNotifications() {
    var promise = callMethod('startNotifications', null);
    return promiseToFuture(promise);
  }
}