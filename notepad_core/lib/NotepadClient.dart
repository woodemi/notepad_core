import 'dart:typed_data';
import 'dart:ui';

import 'package:notepad_core_platform_interface/notepad_core_platform_interface.dart';

import 'Notepad.dart';
import 'models.dart';
import 'NotepadType.dart';
import 'utils.dart';
import 'woodemi/WoodemiClient.dart';

abstract class NotepadClientCallback {
  void handlePointer(List<NotePenPointer> list);

  void handleEvent(NotepadEvent notepadEvent);
}

abstract class NotepadClient {
  static bool support(NotepadScanResult scanResult) {
    return startWith(scanResult.manufacturerData, WoodemiClient.prefix);
  }

  static NotepadClient create(dynamic scanResult) {
    // FIXME Support both native & web
    return WoodemiClient();
  }

  static List<String> get commonServices {
    return [
      SERV__BATTERY,
    ];
  }

  static List<String> get optionalServiceCollection {
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

  List<String> get services;

  List<Tuple2<String, String>> get inputIndicationCharacteristics;

  List<Tuple2<String, String>> get inputNotificationCharacteristics;

  NotepadType notepadType;

  Future<void> completeConnection(void awaitConfirm(bool)) {
    // TODO Cancel
    notepadType.receiveSyncInput().listen((value) {
      callback?.handlePointer(parseSyncData(value));
    });
  }

  NotepadClientCallback callback;

  //#region authorization
  Uint8List _authToken;

  Uint8List get authToken => _authToken;

  void setAuthToken(Uint8List authToken) {
    _authToken = authToken;
  }

  Future<void> claimAuth();

  Future<void> disclaimAuth();
  //#endregion

  //#region device info
  Size getDeviceSize();

  Future<String> getDeviceName();

  Future<void> setDeviceName(String name);

  Future<BatteryInfo> getBatteryInfo();

  Future<int> getDeviceDate();

  Future<void> setDeviceDate(int date);

  Future<int> getAutoLockTime(); // minute

  Future<void> setAutoLockTime(int time); // minute
  //#endregion

  //#region SyncInput
  Future<void> setMode(NotepadMode notepadMode);

  List<NotePenPointer> parseSyncData(Uint8List value);
  //#endregion

  //#region ImportMemo
  Future<MemoSummary> getMemoSummary();

  Future<MemoInfo> getMemoInfo();

  Future<MemoData> importMemo(void progress(int));

  Future<void> deleteMemo();
  //#endregion

  //#region Version
  Future<VersionInfo> getVersionInfo();

  Future<void> upgrade(Uint8List upgradeBlob, Version version, void progress(int));
  //#endregion
}