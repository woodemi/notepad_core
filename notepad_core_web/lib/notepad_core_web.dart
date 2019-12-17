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

  BluetoothDevice _bluetoothDevice;

  @override
  void connect(scanResult) {
    if (messageHandler != null) messageHandler(ConnectionState.connecting);

    final connect = (scanResult as BluetoothDevice).gatt.connect();
    promiseToFuture(connect).then((result) {
      var gatt = (result as BluetoothRemoteGATTServer);
      print('onConnectSuccess $gatt, ${gatt.connected}');
      _bluetoothDevice = gatt.device;
      _bluetoothDevice.addEventListener(BluetoothDevice.disconnectEvent, _handleDisconnectEvent);

      if (messageHandler != null) messageHandler(ConnectionState.connected);
    }, onError: (error) {
      print('onConnectFail $error');
      _bluetoothDevice?.removeEventListener(BluetoothDevice.disconnectEvent, _handleDisconnectEvent);
      _bluetoothDevice = null;

      if (messageHandler != null) messageHandler(ConnectionState.disconnected);
    });
  }

  @override
  void disconnect() {
    _bluetoothDevice?.gatt?.disconnect();
    _bluetoothDevice?.removeEventListener(BluetoothDevice.disconnectEvent, _handleDisconnectEvent);
    _bluetoothDevice = null;
  }

  void _handleDisconnectEvent(dynamic event) {
    print('_handleBluetoothDeviceEvent $event');
    if (getProperty(event, 'target') != _bluetoothDevice) {
      print('Probably MEMORY LEAK!');
      return;
    }
 
    if (messageHandler != null) messageHandler(ConnectionState.disconnected);
  }
}
