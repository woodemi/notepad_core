import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:notepad_core_platform_interface/notepad_core_platform_interface.dart';

import '../Notepad.dart';
import '../NotepadClient.dart';
import '../models.dart';
import 'Woodemi.dart';

class WoodemiClient extends NotepadClient {
  static Uint8List get prefix => Uint8List.fromList([0x57, 0x44, 0x4d]); // 'WDM'

  static List<String> get optionalServices => [
    SERV__COMMAND, SERV__SYNC, SERV__FILE_INPUT, SERV__FILE_OUTPUT,
  ];

  @override
  Tuple2<String, String> get commandRequestCharacteristic => const Tuple2(SERV__COMMAND, CHAR__COMMAND_REQUEST);

  @override
  Tuple2<String, String> get commandResponseCharacteristic => const Tuple2(SERV__COMMAND, CHAR__COMMAND_RESPONSE);

  @override
  Tuple2<String, String> get syncInputCharacteristic => const Tuple2(SERV__SYNC, CHAR__SYNC_INPUT);

  @override
  Tuple2<String, String> get fileInputControlRequestCharacteristic => const Tuple2(SERV__FILE_INPUT, CHAR__FILE_INPUT_CONTROL_REQUEST);

  @override
  Tuple2<String, String> get fileInputControlResponseCharacteristic => const Tuple2(SERV__FILE_INPUT, CHAR__FILE_INPUT_CONTROL_RESPONSE);

  @override
  Tuple2<String, String> get fileInputCharacteristic => const Tuple2(SERV__FILE_INPUT, CHAR__FILE_INPUT);

  @override
  Tuple2<String, String> get fileOutputControlRequestCharacteristic => const Tuple2(SERV__FILE_OUTPUT, CHAR__FILE_OUTPUT_CONTROL_REQUEST);

  @override
  Tuple2<String, String> get fileOutputControlResponseCharacteristic => const Tuple2(SERV__FILE_OUTPUT, CHAR__FILE_OUTPUT_CONTROL_RESPONSE);

  @override
  Tuple2<String, String> get fileOutputCharacteristic => const Tuple2(SERV__FILE_OUTPUT, CHAR__FILE_OUTPUT);

  @override
  List<Tuple2<String, String>> get inputIndicationCharacteristics => [
    commandResponseCharacteristic,
    fileInputControlResponseCharacteristic,
    fileOutputControlResponseCharacteristic,
  ];

  @override
  List<Tuple2<String, String>> get inputNotificationCharacteristics => [
    syncInputCharacteristic,
    fileInputCharacteristic,
  ];

  @override
  Future<void> completeConnection() async {
    await notepadType.sendRequestAsync('Command', commandRequestCharacteristic, Uint8List.fromList([0x01, 0x0A, 0x00, 0x00, 0x00, 0x01]));
    await notepadType.receiveResponseAsync('Command', commandResponseCharacteristic, (data) => data.first == 0x02);
  }

  //#region Device Info
  @override
  Size getDeviceSize() => Size(14800, 21000);

  @override
  Future<String> getDeviceName() async {
    final command = WoodemiCommand(
      request: Uint8List.fromList([0x08, 0x04]),
      intercept: (value) => value.first == 0x0F,
      handle: (value) => utf8.decode(
        value.sublist(1),
      ),
    );
    return await notepadType.executeCommand(command);
  }

  @override
  Future<void> setDeviceName(String name) async {
    final list = utf8.encode(name);
    final data = list.length >= 15
        ? list.sublist(0, 15)
        : list + List.filled(15 - list.length, 0x00);
    return await notepadType.executeCommand(
      WoodemiCommand(
        request: Uint8List.fromList([0x0B] + data),
      ),
    );
  }

  @override
  Future<BatteryInfo> getBatteryInfo() async {
    var percent = await notepadType.fetchProperty(Tuple2(SERV__BATTERY, CHAR__BATTERY_LEVEL), (value) {
      return value.buffer.asByteData().getUint8(0);
    });
    var charging = await notepadType.executeCommand(WoodemiCommand(
      request: Uint8List.fromList([0x08, 0x03]),
      intercept: (value) => value[0] == 0x06 && value[1] == 0x01,
      handle: (value) => value[2] == 0x01
    ));
    return BatteryInfo(percent, charging);
  }

  @override
  Future<int> getDeviceDate() async {
    final command = WoodemiCommand(
      request: Uint8List.fromList([0x08, 0x01]),
      intercept: (value) => value.first == 0x0C,
      handle: (value) => value.buffer.asByteData().getUint32(2, Endian.little),
    );
    return await notepadType.executeCommand(command);
  }

  @override
  Future<void> setDeviceDate(int second) async {
    final data = Uint32List.fromList([second]).buffer.asUint8List();
    await notepadType.executeCommand(
      WoodemiCommand(
        request: Uint8List.fromList(
          [0x0A] + data.toList(),
        ),
      ),
    );
  }

  @override
  Future<void> setAutoLockTime(int minute) async {
    var byteData = ByteData(4);
    final second = Duration(minutes: minute).inSeconds;
    byteData.setUint32(0, second, Endian.little);
    await notepadType.executeCommand(
      WoodemiCommand(
        request: Uint8List.fromList(
          [0x11, 0x01] + byteData.buffer.asUint8List(),
        ),
      ),
    );
  }

  @override
  Future<int> getAutoLockTime() async {
    final command = WoodemiCommand(
      request: Uint8List.fromList([0x08, 0x05]),
      intercept: (value) => value.first == 0x10,
      handle: (value) {
        final byteData = value.buffer.asByteData();
        final seconds = byteData.getUint32(2, Endian.little);
        return Duration(seconds: seconds).inMinutes;
      },
    );
    return await notepadType.executeCommand(command);
  }
  //#endregion
}