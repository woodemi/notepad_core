import 'package:notepad_core_platform_interface/notepad_core_platform_interface.dart';

import 'models.dart';
import 'NotepadType.dart';
import 'utils.dart';
import 'woodemi/WoodemiClient.dart';

abstract class NotepadClient {
  static bool support(NotepadScanResult scanResult) {
    return startWith(scanResult.manufacturerData, WoodemiClient.prefix);
  }

  static NotepadClient create(dynamic scanResult) {
    // FIXME Support both native & web
    return WoodemiClient();
  }

  static List<String> get optionalServices {
    return [
      ...WoodemiClient.optionalServices,
    ];
  }

  Tuple2<String, String> get commandRequestCharacteristic;

  Tuple2<String, String> get commandResponseCharacteristic;

  Tuple2<String, String> get syncInputCharacteristic;

  Tuple2<String, String> get fileInputControlRequestCharacteristic;

  Tuple2<String, String> get fileInputControlResponseCharacteristic;

  Tuple2<String, String> get fileInputCharacteristic;

  Tuple2<String, String> get fileOutputControlRequestCharacteristic;

  Tuple2<String, String> get fileOutputControlResponseCharacteristic;

  Tuple2<String, String> get fileOutputCharacteristic;

  List<Tuple2<String, String>> get inputIndicationCharacteristics;

  List<Tuple2<String, String>> get inputNotificationCharacteristics;

  NotepadType notepadType;

  Future<void> completeConnection();
}