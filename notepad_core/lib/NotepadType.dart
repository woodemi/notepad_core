import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:notepad_core_platform_interface/notepad_core_platform_interface.dart';

import 'Notepad.dart';
import 'NotepadClient.dart';

class NotepadType {
  final NotepadClient _notepadClient;

  NotepadType(this._notepadClient) {
    _notepadClient.notepadType = this;
  }

  Future<void> configCharacteristics() async {
    for (var serviceCharacteristic in _notepadClient.inputIndicationCharacteristics) {
      print('configInputCharacteristic (${serviceCharacteristic.item1}, ${serviceCharacteristic.item2}), indication');
      await NotepadCorePlatform.instance.setNotifiable(serviceCharacteristic, BleInputProperty.indication);
    }
    for (var serviceCharacteristic in _notepadClient.inputNotificationCharacteristics) {
      print('configInputCharacteristic (${serviceCharacteristic.item1}, ${serviceCharacteristic.item2}), notification');
      await NotepadCorePlatform.instance.setNotifiable(serviceCharacteristic, BleInputProperty.notification);
    }
  }

  int mtu;

  Future<void> configMtu(int expectedMtu) async {
    mtu = await NotepadCorePlatform.instance.requestMtu(expectedMtu) - GATT_HEADER_LENGTH;
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

  Future<T> fetchProperty<T>(Tuple2<String, String> serviceCharacteristic, Handle<T> handle) async {
    NotepadCorePlatform.instance.readValue(serviceCharacteristic);
    var value = await receiveResponseAsync('Property', serviceCharacteristic, (value) => true);
    return handle(value);
  }

  Future<T> executeCommand<T>(NotepadCommand<T> command) async {
    await sendRequestAsync('Command', _notepadClient.commandRequestCharacteristic, command.request);
    var response = await receiveResponseAsync('Command', _notepadClient.commandResponseCharacteristic, command.intercept);
    return command.handle(response);
  }

  Stream<Uint8List> receiveSyncInput() => receiveValue(_notepadClient.syncInputCharacteristic).map((value) {
    print('onSyncInputReceive ${hex.encode(value)}');
    return value;
  });

  Future<T> executeFileInputControl<T>(NotepadCommand<T> command) async {
    await sendRequestAsync('FileInputControl', _notepadClient.fileInputControlRequestCharacteristic, command.request);
    var response = await receiveResponseAsync('FileInputControl', _notepadClient.fileInputControlResponseCharacteristic, command.intercept);
    return command.handle(response);
  }

  Stream<Uint8List> receiveFileInput() => receiveValue(_notepadClient.fileInputCharacteristic).map((value) {
    print('onFileInputReceive: ${hex.encode(value)}');
    return value;
  });
}