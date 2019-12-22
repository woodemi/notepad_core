import 'dart:typed_data';

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

enum NotepadMode { Sync, Common }

class BatteryInfo {
  final int percent;
  final bool charging;

  BatteryInfo(this.percent, this.charging);
}

class NotePenPointer {
  int x;
  int y;
  int t;
  int p;

  NotePenPointer(this.x, this.y, this.t, this.p);

  NotePenPointer.fromMap(map)
      : this.x = map['x'],
        this.y = map['y'],
        this.t = map['t'],
        this.p = map['p'];

  Map toMap() => {
    'x': x,
    'y': y,
    't': t,
    'p': p,
  };

  @override
  bool operator ==(other) =>
      x == other.x && y == other.y && t == other.t && p == other.p;
}

class MemoSummary {
  final int memoCount;
  final int totalCapacity;
  final int freeCapacity;
  final int usedCapacity;

  MemoSummary(this.memoCount, this.totalCapacity, this.freeCapacity, this.usedCapacity);

  MemoSummary.fromMap(map)
      : this.memoCount = map['memoCount'],
        this.totalCapacity = map['totalCapacity'],
        this.freeCapacity = map['freeCapacity'],
        this.usedCapacity = map['usedCapacity'];

  double get totalCapacityInMegas => totalCapacity / 1024.0 / 1024.0;

  double get freeCapacityInMegas => freeCapacity / 1024.0 / 1024.0;

  double get usedCapacityInMegas => usedCapacity / 1024.0 / 1024.0;

  @override
  String toString() => '$memoCount, $totalCapacity, $freeCapacity, $usedCapacity';
}

class MemoInfo {
  final int sizeInByte;
  // milliseconds
  final int createdAt;
  final int partIndex;
  // Rest part count in current transportation
  final int restCount;

  MemoInfo(this.sizeInByte, this.createdAt, this.partIndex, this.restCount);

  MemoInfo.fromMap(map)
      : this.sizeInByte = map['sizeInByte'],
        this.createdAt = map['createdAt'],
        this.partIndex = map['partIndex'],
        this.restCount = map['restCount'];

  @override
  String toString() => '$sizeInByte, $createdAt, $partIndex, $restCount';
}