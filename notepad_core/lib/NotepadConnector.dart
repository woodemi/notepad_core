
import 'package:flutter/foundation.dart';
import 'package:notepad_core_platform_interface/notepad_core_platform_interface.dart';

import 'models.dart';
import 'NotepadClient.dart';
import 'NotepadType.dart';

final notepadConnector = NotepadConnector._();

final _tag = 'NotepadConnector';

class NotepadConnector {
  NotepadConnector._() {
    NotepadCorePlatform.instance.messageHandler = _handleMessage;
  }

  Future<dynamic> requestDevice() {
    if (!kIsWeb) throw UnimplementedError('Web platform only for now');

    return NotepadCorePlatform.instance.requestDevice(optionalServices: NotepadClient.optionalServices);
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
      .where(NotepadClient.support);
  }

  NotepadClient _notepadClient;
  NotepadType _notepadType;

  void connect(scanResult) {
    _notepadClient = NotepadClient.create(scanResult);
    _notepadType = NotepadType(_notepadClient);
    NotepadCorePlatform.instance.connect(scanResult);
  }

  void disconnect() {
    _notepadClient = null;
    _notepadType = null;
    NotepadCorePlatform.instance.disconnect();
  }

  Future<void> _handleMessage(NotepadCoreMessage message) async {
    print('$_tag handleMessage $message');
    if (message is ConnectionState) {
      switch(message) {
        case ConnectionState.connected:
          await _notepadType.configCharacteristics();
          await _notepadClient.completeConnection();
          break;
        case ConnectionState.disconnected:
          _notepadClient = null;
          _notepadType = null;
          break;
        default:
          print('ConnectionState ${message.value}');
      }
    }
  }
}
