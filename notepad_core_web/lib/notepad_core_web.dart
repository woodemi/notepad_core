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
}
