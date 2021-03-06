@JS()
library notepad_core_js;

import 'dart:html' show EventTarget;
import 'dart:typed_data';

import 'package:js/js.dart';

import 'js_facade.dart';

@JS('navigator.bluetooth')
external EventTarget get _bluetooth;

@JS('navigator.bluetooth.addEventListener')
external void addBluetoothListener(String type, listener(event), [bool useCapture]);

@JS('navigator.bluetooth.removeEventListener')
external void removeBluetoothListener(String type, listener(event), [bool useCapture]);

final Bluetooth bluetooth = Bluetooth(_bluetooth);

class Bluetooth extends Delegate<dynamic> {
  /// Event type should be [const]
  static const availabilityEvent = 'availabilitychanged';

  Bluetooth(dynamic delegate) : super(delegate);

  Future<bool> getAvailability() {
    var promise = callMethod('getAvailability', null);
    return promiseToFuture(promise);
  }

  Future<BluetoothDevice> requestDevice(ScanOptions options) {
    var promise = callMethod('requestDevice', [options]);
    return promiseToFuture(promise).then((onValue) => BluetoothDevice(onValue));
  }
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

  Future<Uint8List> readValue() {
    var promise = callMethod('readValue', null);
    return promiseToFuture(promise).then((dataView) => (dataView as ByteData).buffer.asUint8List());
  }

  Future<dynamic> writeValue(Uint8List bytes) {
    var promise = callMethod('writeValue', [bytes]);
    return promiseToFuture(promise);
  }

  Future<dynamic> startNotifications() {
    var promise = callMethod('startNotifications', null);
    return promiseToFuture(promise);
  }
}