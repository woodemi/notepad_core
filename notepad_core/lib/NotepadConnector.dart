import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:notepad_core_platform_interface/notepad_core_platform_interface.dart';
import 'package:convert/convert.dart';

import 'models.dart';
import 'Notepad.dart';
import 'NotepadClient.dart';

const GSS_SUFFIX = '0000-1000-8000-00805f9b34fb';

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

  void connect(scanResult) {
    _notepadClient = NotepadClient.create(scanResult);
    NotepadCorePlatform.instance.connect(scanResult);
  }

  void disconnect() {
    _notepadClient = null;
    NotepadCorePlatform.instance.disconnect();
  }

  Future<void> _handleMessage(NotepadCoreMessage message) async {
    print('$_tag handleMessage $message');
    if (message is ConnectionState) {
      switch(message) {
        case ConnectionState.connected:
          await configCharacteristics();
          await _notepadClient.completeConnection();
          break;
        case ConnectionState.disconnected:
          _notepadClient = null;
          break;
        default:
          print('ConnectionState ${message.value}');
      }
    }
  }

  Future<void> configCharacteristics() async {
    for (var serviceCharacteristic in _notepadClient.inputIndicationCharacteristics) {
      print('configInputCharacteristic $serviceCharacteristic, indication');
      await NotepadCorePlatform.instance.setNotifiable(serviceCharacteristic);
    }
  }

  Future<void> sendRequestAsync(String messageHead, Tuple2<String, String> serviceCharacteristic, Uint8List request) async {
    await NotepadCorePlatform.instance.writeValue(serviceCharacteristic, request);
    print('on${messageHead}Send: ${hex.encode(request)}');
  }

  Stream<Uint8List> receiveValue(Tuple2<String, String> serviceCharacteristic) =>
      NotepadCorePlatform.instance.inputValueStream.where((cv) {
        return cv.item1 == serviceCharacteristic.item2 || '0000${cv.item1}-$GSS_SUFFIX' == serviceCharacteristic.item2;
      }).map((cv) => cv.item2);

  Future<Uint8List> receiveResponseAsync(String messageHead, Tuple2<String, String> serviceCharacteristic, Predicate intercept) async {
    var response = await receiveValue(serviceCharacteristic).firstWhere(intercept);
    print('on${messageHead}Receive: ${hex.encode(response)}');
    return response;
  }
}
