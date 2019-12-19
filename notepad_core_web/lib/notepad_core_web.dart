import 'dart:html';
import 'dart:typed_data';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:notepad_core_platform_interface/notepad_core_platform_interface.dart';

import 'js_facade.dart';
import 'notepad_core_js.dart';

class NotepadCorePlugin extends NotepadCorePlatform {
  static void registerWith(Registrar registrar) {
    NotepadCorePlatform.instance = NotepadCorePlugin();
  }

  @override
  Future<dynamic> requestDevice({
    List<String> optionalServices,
  }) async {
    var requestDevice = Bluetooth.requestDevice(ScanOptions(
      optionalServices: optionalServices.map(getServiceUUID).toList(),
      acceptAllDevices: true,
    ));
    return BluetoothDevice(await promiseToFuture(requestDevice));
  }

  @override
  void startScan() {
    throw UnimplementedError('Not implemented in NotepadCorePlugin');
  }

  @override
  void stopScan() {
    throw UnimplementedError('Not implemented in NotepadCorePlugin');
  }

  @override
  Stream<dynamic> get scanResultStream {
    throw UnimplementedError('Not implemented in NotepadCorePlugin');
  }

  BluetoothRemoteGATTServer _connectGatt;

  @override
  void connect(scanResult) {
    (scanResult as BluetoothDevice).gatt.connect().then((result) {
      _connectGatt = result;
      print('onConnectSuccess $_connectGatt, ${_connectGatt.connected}');
      _connectGatt.device.addEventListener(BluetoothDevice.disconnectEvent, _handleDisconnectEvent);

      if (messageHandler != null) messageHandler(ConnectionState.connected);
    }, onError: (error) {
      print('onConnectFail $error');
      if (messageHandler != null) messageHandler(ConnectionState.disconnected);
    });

    if (messageHandler != null) messageHandler(ConnectionState.connecting);
  }

  @override
  void disconnect() {
    _connectGatt?.disconnect();
    _connectGatt?.device?.removeEventListener(BluetoothDevice.disconnectEvent, _handleDisconnectEvent);
    _connectGatt = null;
  }

  /// FIXME [removeEventListener] not work
  void _handleDisconnectEvent(Event event) {
    print('_handleDisconnectEvent ${event.target.hashCode}');
    if (event.target != _connectGatt?.device?.delegate) {
      print('Probably MEMORY LEAK!');
      return;
    }

    _connectGatt?.device?.removeEventListener(BluetoothDevice.disconnectEvent, _handleDisconnectEvent);
    _connectGatt = null;
 
    if (messageHandler != null) messageHandler(ConnectionState.disconnected);
  }

  @override
  Future<void> writeValue(Tuple2<String, String> serviceCharacteristic, Uint8List value) async {
    var characteristic = await getCharacteristic(_connectGatt, serviceCharacteristic);
    await characteristic.writeValue(value);
  }
}

Future<BluetoothRemoteGATTCharacteristic> getCharacteristic(BluetoothRemoteGATTServer gatt, Tuple2<String, String> serviceCharacteristic) async {
  var service = await gatt.getPrimaryService(getServiceUUID(serviceCharacteristic.item1));
  return await service.getCharacteristic(getCharacteristicUUID(serviceCharacteristic.item2));
}
