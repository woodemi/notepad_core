import 'dart:typed_data';

import 'utils.dart';
import 'woodemi/Woodemi.dart';

bool support(NotepadScanResult scanResult) {
  return startWith(scanResult.manufacturerData, WOODEMI_PREFIX);
}

class NotepadScanResult {
  String name;
  String deviceId;
  Uint8List manufacturerData;
  int rssi;

  NotepadScanResult.fromMap(map)
      : name = map['name'],
        deviceId = map['deviceId'],
        manufacturerData = map['manufacturerData'],
        rssi = map['rssi'];

  Map toMap() => {
        'name': name,
        'deviceId': deviceId,
        'manufacturerData': manufacturerData,
        'rssi': rssi,
      };
}