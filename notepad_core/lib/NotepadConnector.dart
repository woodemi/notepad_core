import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:notepad_core_platform_interface/notepad_core_platform_interface.dart';
import 'package:convert/convert.dart';

import 'Notepad.dart';

const SUFFIX = 'ba5e-f4ee-5ca1-eb1e5e4b1ce0';

const SERV__COMMAND = '57444d01-$SUFFIX';
const CHAR__COMMAND_REQUEST = '57444e02-$SUFFIX';
const CHAR__COMMAND_RESPONSE = CHAR__COMMAND_REQUEST;

final notepadConnector = NotepadConnector._();

final _tag = 'NotepadConnector';

class NotepadConnector {
  NotepadConnector._() {
    NotepadCorePlatform.instance.messageHandler = _handleMessage;
  }

  Future<dynamic> requestDevice() {
    if (!kIsWeb) throw UnimplementedError('Web platform only for now');

    return NotepadCorePlatform.instance.requestDevice(optionalServices: [SERV__COMMAND]);
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
          await configCharacteristics();
          await completeConnection();
          break;
        default:
          print('ConnectionState ${message.value}');
      }
    }
  }

  Future<void> configCharacteristics() async {
    await NotepadCorePlatform.instance.setNotifiable(Tuple2(SERV__COMMAND, CHAR__COMMAND_REQUEST));
  }

  Future<void> completeConnection() async {
    await sendRequestAsync('Command', Tuple2(SERV__COMMAND, CHAR__COMMAND_REQUEST), Uint8List.fromList([0x01, 0x0A, 0x00, 0x00, 0x00, 0x01]));
  }

  Future<void> sendRequestAsync(String messageHead, Tuple2<String, String> serviceCharacteristic, Uint8List request) async {
    await NotepadCorePlatform.instance.writeValue(serviceCharacteristic, request);
    print('on${messageHead}Send: ${hex.encode(request)}');
  }
}
