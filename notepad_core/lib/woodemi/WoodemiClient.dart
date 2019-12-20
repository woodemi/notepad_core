import 'dart:typed_data';

import 'package:notepad_core_platform_interface/notepad_core_platform_interface.dart';

import '../NotepadClient.dart';
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
}