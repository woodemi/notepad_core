import 'dart:typed_data';

class NotepadScanResult {
  String type;
  String name;
  String deviceId;
  Uint8List manufacturerData;
  int rssi;
  String showId;

  NotepadScanResult.fromMap(map)
      : type = map['type'] ?? '',
        name = map['name'],
        deviceId = map['deviceId'],
        manufacturerData = map['manufacturerData'],
        rssi = map['rssi'],
        showId = '${map['deviceId']}'.toUpperCase().replaceAll(':', '');

  Map toMap() => {
        'type': type,
        'name': name,
        'deviceId': deviceId,
        'manufacturerData': manufacturerData,
        'rssi': rssi,
        'showId': showId,
      };
}

enum NotepadMode { Sync, Common }

class BatteryInfo {
  final int percent;
  final bool charging;

  BatteryInfo(this.percent, this.charging);
}

class VersionInfo {
  Version hardware;
  Version software;

  VersionInfo({this.hardware, this.software});

  VersionInfo.fromMap(map)
      : this.hardware = Version.fromMap(map['hardware']),
        this.software = Version.fromMap(map['software']);
}

class Version {
  final int major;
  final int minor;
  final int patch;

  Version(int major, [int minor, int patch])
      : this.major = major,
        this.minor = minor,
        this.patch = patch;

  Version.fromMap(map)
      : this.major = map['major'],
        this.minor = map['minor'],
        this.patch = map['patch'];

  Uint8List get bytes => Uint8List.fromList([
    major,
    if (minor != null) minor,
    if (patch != null) patch,
  ]);

  Map toMap() => {
    'major': major,
    'minor': minor,
    'patch': patch,
  };

  String get description =>
      '$major' +
          (minor != null ? '.$minor' : '') +
          (patch != null ? '.$patch' : '');
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
  String toString() => 'memoCount = $memoCount, totalCapacity = $totalCapacity, freeCapacity = $freeCapacity, usedCapacity = $usedCapacity';
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
  String toString() => 'sizeInByte = $sizeInByte, createdAt = $createdAt, partIndex = $partIndex, restCount = $restCount';
}

class MemoData {
  MemoInfo memoInfo;
  List<NotePenPointer> pointers;

  MemoData(this.memoInfo, this.pointers);

  MemoData.from(MemoInfo memoInfo, List<NotePenPointer> pointers) {
    this.memoInfo = memoInfo;
    this.pointers = pointers;
  }

  MemoData.fromMap(map) {
    this.memoInfo = MemoInfo.fromMap(map['memoInfo']);
    var pointers = List<NotePenPointer>();
    for (final m in map['pointers'])
      pointers.add(NotePenPointer.fromMap(m));
    this.pointers = pointers;
  }

  @override
  String toString() => '$memoInfo, pointers[${pointers.length}]';
}

abstract class NotepadEvent {

  factory NotepadEvent.KeyEvent(KeyEventType type, KeyEventCode code) {
    return KeyEvent(type, code);
  }

  factory NotepadEvent.BatteryAlertEvent() {
    return BatteryAlertEvent();
  }

  factory NotepadEvent.ChargingStatusEvent(ChargingStatusEventType type) {
    return ChargingStatusEvent(type);
  }

  factory NotepadEvent.StorageAlertEvent() {
    return StorageAlertEvent();
  }
}

class KeyEvent implements NotepadEvent {
  final KeyEventType type;
  final KeyEventCode code;

  KeyEvent(this.type, this.code);
}

enum KeyEventType { KeyUp }

enum KeyEventCode { Main }

class BatteryAlertEvent implements NotepadEvent {
  BatteryAlertEvent();
}

class ChargingStatusEvent implements NotepadEvent {
  final ChargingStatusEventType type;

  ChargingStatusEvent(this.type);
}

enum ChargingStatusEventType { PowerOn, PowerOff }

class StorageAlertEvent implements NotepadEvent {
  StorageAlertEvent();
}