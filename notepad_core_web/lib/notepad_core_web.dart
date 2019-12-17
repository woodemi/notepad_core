import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js_util.dart' show promiseToFuture;
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
    var connect = (scanResult as BluetoothDevice).gatt.connect();
    promiseToFuture(connect).then((gatt) {
      print('onConnectSuccess $gatt');
      _connectGatt = gatt;
    }, onError: (error) {
      print('onConnectFail $error');
      _connectGatt = null;
    });
  }

  @override
  void disconnect() {
    _connectGatt?.disconnect();
    _connectGatt = null;
  }
}
