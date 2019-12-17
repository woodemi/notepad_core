import 'package:flutter/foundation.dart';
import 'package:notepad_core_platform_interface/notepad_core_platform_interface.dart';

import 'Notepad.dart';

final notepadConnector = NotepadConnector._();

class NotepadConnector {
  NotepadConnector._();

  Future<dynamic> requestDevice() {
    if (!kIsWeb) throw UnimplementedError('Web platform only for now');

    return NotepadCorePlatform.instance.requestDevice();
  }

  void startScan() {
    if (kIsWeb) throw UnimplementedError('Native platform only for now');

    NotepadCorePlatform.instance.startScan();
  }

  void stopScan() {
    if (kIsWeb) throw UnimplementedError('Native platform only for now');

    NotepadCorePlatform.instance.stopScan();
  }

  Stream<NotepadScanResult> get scanResultStream {
    if (kIsWeb) throw UnimplementedError('Native platform only for now');

    return NotepadCorePlatform.instance.scanResultStream
      .map((item) => NotepadScanResult.fromMap(item))
      .where(support);
  }
}
