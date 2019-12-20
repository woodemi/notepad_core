import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:notepad_core_platform_interface/notepad_core_platform_interface.dart';

import 'Notepad.dart';
import 'NotepadClient.dart';

const GSS_SUFFIX = '0000-1000-8000-00805f9b34fb';

class NotepadType {
  final NotepadClient _notepadClient;

  NotepadType(this._notepadClient) {
    _notepadClient.notepadType = this;
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