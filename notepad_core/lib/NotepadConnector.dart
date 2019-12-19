import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:notepad_core_platform_interface/notepad_core_platform_interface.dart';
import 'package:convert/convert.dart';

import 'Notepad.dart';

final notepadConnector = NotepadConnector._();

final _tag = 'NotepadConnector';

class NotepadConnector {
  NotepadConnector._() {
    NotepadCorePlatform.instance.messageHandler = _handleMessage;
  }

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

  void connect(scanResult) {
    NotepadCorePlatform.instance.connect(scanResult);
  }

  void disconnect() {
    NotepadCorePlatform.instance.disconnect();
  }

  Future<void> _handleMessage(NotepadCoreMessage message) async {
    print('$_tag handleMessage $message');
    if (message is ConnectionState) {
      switch(message) {
        case ConnectionState.connected:
          await completeConnection();
          break;
        default:
          print('ConnectionState ${message.value}');
      }
    }
  }

  Future<dynamic> completeConnection() async {
    await sendRequestAsync('Command', Tuple2('57444d01-ba5e-f4ee-5ca1-eb1e5e4b1ce0', '57444e02-ba5e-f4ee-5ca1-eb1e5e4b1ce0'), Uint8List.fromList([0x01, 0x0A, 0x00, 0x00, 0x00, 0x00]));
  }

  Future<void> sendRequestAsync(String messageHead, Tuple2<String, String> serviceCharacteristic, Uint8List request) async {
    await NotepadCorePlatform.instance.writeValue(serviceCharacteristic, request);
    print('on${messageHead}Send: ${hex.encode(request)}');
  }
}
