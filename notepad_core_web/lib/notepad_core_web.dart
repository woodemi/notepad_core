import 'dart:html';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js_util.dart' show promiseToFuture, getProperty;
import 'package:notepad_core_platform_interface/notepad_core_platform_interface.dart';

import 'notepad_core_js.dart';

class NotepadCorePlugin extends NotepadCorePlatform {
  static void registerWith(Registrar registrar) {
    NotepadCorePlatform.instance = NotepadCorePlugin();
  }

  @override
  Future<dynamic> requestDevice() async {
    var requestDevice = Bluetooth.requestDevice(ScanOptions(
      acceptAllDevices: true,
    ));
    return promiseToFuture(requestDevice);
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
    final connect = (scanResult as BluetoothDevice).gatt.connect();
    promiseToFuture(connect).then((result) {
      _connectGatt = (result as BluetoothRemoteGATTServer);
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
    if (event.target != _connectGatt?.device) {
      print('Probably MEMORY LEAK!');
      return;
    }

    _connectGatt?.device?.removeEventListener(BluetoothDevice.disconnectEvent, _handleDisconnectEvent);
    _connectGatt = null;
 
    if (messageHandler != null) messageHandler(ConnectionState.disconnected);
  }
}
