import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';
import 'package:notepad_core_platform_interface/notepad_core_platform_interface.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quiver/iterables.dart' show partition;

import '../Notepad.dart';
import '../NotepadClient.dart';
import '../models.dart';
import '../utils.dart';
import 'FileRecord.dart';
import 'ImageTransmission.dart';
import 'Woodemi.dart';

typedef _IntCallback = void Function(int);

class WoodemiClient extends NotepadClient {
  static Uint8List get prefix => Uint8List.fromList([0x57, 0x44, 0x4d]); // 'WDM'

  static List<String> get optionalServices => [
    ...NotepadClient.commonServices, SERV__COMMAND, SERV__SYNC, SERV__FILE_INPUT, SERV__FILE_OUTPUT,
  ];

  final WoodemiType woodemiType;

  WoodemiClient._(this.woodemiType);

  static WoodemiClient create(Uint8List data) {
    assert(startWith(data, prefix));
    var type = data.sublist(3, 5);

    if (listEquals(type, WoodemiType.UGEE_CN.type)) {
      return WoodemiClient._(WoodemiType.UGEE_CN);
    } else if (listEquals(type, WoodemiType.UGEE_GLOBAL.type)) {
      return WoodemiClient._(WoodemiType.UGEE_GLOBAL);
    } else if (listEquals(type, WoodemiType.EMRIGHT_CN.type)) {
      return WoodemiClient._(WoodemiType.EMRIGHT_CN);
    } else if (listEquals(type, WoodemiType.REALTAK_CN.type)) {
      return WoodemiClient._(WoodemiType.REALTAK_CN);
    } else {
      return WoodemiClient._(WoodemiType.UGEE_CN);
    }
  }

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
  List<String> get services => optionalServices;

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
  Future<void> completeConnection(void awaitConfirm(bool)) async {
    var accessResult = await _checkAccess(authToken ?? defaultAuthToken, 10, awaitConfirm);
    switch(accessResult) {
      case AccessResult.Denied:
        throw AccessException.Denied;
      case AccessResult.Unconfirmed:
        throw AccessException.Unconfirmed;
      default:
        break;
    }

    await notepadType.configMtu(MTU_WUART);
    _configSyncInput();
    _configMessageInput();
  }

  @override
  Future<void> clear() {
    _clearSyncInput();
    _clearMessageIput();
  }

  StreamSubscription<Uint8List> _receiveSyncInputSubscription = null;
  StreamSubscription<dynamic> _receiveOtherMessageSubscription = null;

  void _configSyncInput() {
    _clearSyncInput();
    _receiveSyncInputSubscription =
        notepadType.receiveSyncInput().listen((value) {
          callback?.handlePointer(parseSyncData(value));
        });
  }

  void _clearSyncInput() {
    _receiveSyncInputSubscription?.cancel();
    _receiveSyncInputSubscription = null;
  }

  StreamSubscription<Uint8List> _receiveMessageInputSubscription = null;

  void _configMessageInput() {
    _clearMessageIput();
    _receiveMessageInputSubscription = notepadType
        .receiveValue(commandResponseCharacteristic)
        .where((value) => value.first == 0x06 || value.first == 0x0E)
        .map((value) {
          print('onMessageInputReceive ${hex.encode(value)}');
          return value;
        })
        .listen(_handleMessageInput);


    _receiveOtherMessageSubscription =
        NotepadCorePlatform.instance.otherMessageStream.listen((map) async {
          switch (map["method"]) {
            case "stateChangeA2":
/*
  state=513 message=初始化 …
  state=514 message=启动中 …
  state=516 message=连接设备…
  state=517 message=准备升级环境 …
  state=521 message=正在升级…
  state=524 message=固件激活中
  state=258 message=固件激活成功
 */
              break;
            case "upgradeFailA2":
              upgradeProgress(-1);
              break;
            case "upgradeProgressA2":
              print('upgrading progress = ${map["value"]}');
              upgradeProgress(int.parse(map["value"]));
              break;
          }
        });
  }

  void _clearMessageIput() {
    _receiveMessageInputSubscription?.cancel();
    _receiveMessageInputSubscription = null;

    _receiveOtherMessageSubscription?.cancel();
    _receiveOtherMessageSubscription = null;
  }

  void _handleMessageInput(Uint8List value) {
    print('_handleMessageInput: ${hex.encode(value)}');
    var tuple01 = value.sublist(0, 2);
    if (listEquals(tuple01, [0x06, 0x00])) {
      if (value[2] == 0x01)
        callback?.handleEvent(NotepadEvent.KeyEvent(KeyEventType.KeyUp, KeyEventCode.Main));
    } else if (listEquals(tuple01, [0x06, 0x01])) {
      var type = value[2] == 0x01 ? ChargingStatusEventType.PowerOn : ChargingStatusEventType.PowerOff;
      callback?.handleEvent(NotepadEvent.ChargingStatusEvent(type));
    } else if (listEquals(tuple01, [0x0E, 0x01])) {
      callback?.handleEvent(NotepadEvent.BatteryAlertEvent());
    } else if (listEquals(tuple01, [0x0E, 0x02])) {
      callback?.handleEvent(NotepadEvent.StorageAlertEvent());
    }
  }

  //#region authorization
  Future<AccessResult> _checkAccess(Uint8List authToken, int seconds, void awaitConfirm(bool)) async {
    var command = WoodemiCommand(
      request: Uint8List.fromList([0x01, seconds] + authToken),
      intercept: (data) => data.first == 0x02,
      handle: (data) => data[1],
    );
    var response = await notepadType.executeCommand(command);
    switch(response) {
      case 0x00:
        return AccessResult.Denied;
      case 0x01:
        awaitConfirm(true);
        var receiveConfirmAsync = notepadType.receiveResponseAsync('Confirm',
          commandResponseCharacteristic, (value) => value.first == 0x03
        ).then((value) => value[1] == 0x00);
        var confirm = await receiveConfirmAsync.timeout(Duration(seconds: seconds), onTimeout: () => false);
        return confirm ? AccessResult.Confirmed : AccessResult.Unconfirmed;
      case 0x02:
        return AccessResult.Approved;
      default:
        throw Exception('Unknown error');
    }
  }

  @override
  void setAuthToken(Uint8List authToken) {
    var newAuthToken = authToken ?? defaultAuthToken;
    assert(newAuthToken.length == 4, 'authToken should be 4 in length !');
    super.setAuthToken(newAuthToken);
  }

  Future<void> claimAuth() => _sendAuthRequest(authToken, true);

  Future<void> disclaimAuth() => _sendAuthRequest(authToken, false);

  Future<void> _sendAuthRequest(Uint8List authToken, bool claim) =>
      notepadType.executeCommand(WoodemiCommand(
        request: Uint8List.fromList(
          [0x04, claim ? 0x00 : 0x01] + authToken,
        ),
      ));

  //#endregion

  //#region Device Info
  int get width => woodemiType.width;

  int get height => woodemiType.height;

  @override
  Size getDeviceSize() => Size(width.toDouble(), height.toDouble());

  @override
  String getDeviceType() => woodemiType.deviceType;

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
      handle: (value) => value.buffer.asByteData().getUint32(1, Endian.little),
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
        //  hardvare <= 1.1.1：value = [16, 5, 140, 10, 0]
        //  hardvare > 1.1.1： value = [16, 5, 140, 10, 0, 0]
        //  此处兼容<=1.1.1版本
        var fullValue = Uint8List.fromList(value.toList() + [0]);
        final byteData = fullValue.buffer.asByteData();
        final seconds = byteData.getUint32(2, Endian.little);
        return Duration(seconds: seconds).inMinutes;
      },
    );
    return await notepadType.executeCommand(command);
  }
  //#endregion

  //#region SyncInput
  @override
  Future<void> setMode(NotepadMode notepadMode) async {
    var mode = notepadMode == NotepadMode.Sync ? 0x00 : 0x01;
    var bleConnectionPriority = notepadMode == NotepadMode.Sync ? BleConnectionPriority.high : BleConnectionPriority.balanced;
    notepadType.configConnectionPriority(bleConnectionPriority);
    await notepadType.executeCommand(
      WoodemiCommand(
        request: Uint8List.fromList([0x05, mode]),
      ),
    );
  }

  //#region ImportMemo
  @override
  Future<MemoSummary> getMemoSummary() {
    var handle = (Uint8List value) {
      var byteData = value.buffer.asByteData();
      var position = 1; // skip 1
      var totalCapacity = byteData.getUint32(position, Endian.little);
      var freeCapacity = byteData.getUint32(position += 4, Endian.little);
      var usedCapacity = byteData.getUint32(position += 4, Endian.little);
      var memoCount = byteData.getUint16(position += 4, Endian.little);
      return MemoSummary(memoCount, totalCapacity, freeCapacity, usedCapacity);
    };
    return notepadType.executeCommand(WoodemiCommand(
      request: Uint8List.fromList([0x08, 0x02]),
      intercept: (value) => value.first == 0x0D,
      handle: handle,
    ));
  }

  @override
  Future<MemoInfo> getMemoInfo() async {
    var largeDataInfo = await getLargeDataInfo();
    return MemoInfo(
      largeDataInfo.sizeInByte - ImageTransmission.EMPTY_LENGTH,
      largeDataInfo.createdAt,
      largeDataInfo.partIndex,
      largeDataInfo.restCount,
    );
  }

  Future<MemoInfo> getLargeDataInfo() async {
    var data = fileInfo.item1 + fileInfo.item2;
    var handle = (Uint8List value) {
      var byteData = value.buffer.asByteData();
      var position = 1; // skip 1
      var partIndex = byteData.getUint8(position);
      var restCount = byteData.getUint8(position += 1);

      position += 1;
      var chars = value.sublist(position, position + fileInfo.item2.length);
      var seconds = int.parse(String.fromCharCodes(chars, 0, chars.length), radix: 16);
      var createdAt = Duration(seconds: seconds).inMilliseconds;
      
      var sizeInByte = byteData.getUint32(position += fileInfo.item2.length, Endian.little);
      return MemoInfo(sizeInByte, createdAt, partIndex, restCount);
    };

    return notepadType.executeFileInputControl(WoodemiCommand(
      request: Uint8List.fromList([0x02] + data),
      intercept: (value) => value.first == 0x03,
      handle: handle,
    ));
  }

  final fileInfo = Tuple2(
    Uint8List.fromList([0x00, 0x01]), // imageId
    Uint8List.fromList([ // imageVersion
      0x01, 0x00, 0x00, // Build Version
      0x41, // Stack Version
      0x11, 0x11, 0x11, // Hardware Id
      0x01 // Manufacturer Id
    ])
  );

  @override
  Future<MemoData> importMemo(void progress(int)) async {
    Tuple2<MemoInfo, Uint8List> tuple = await importImageData(progress);
    return MemoData(tuple.item1, parseMemo(tuple.item2, tuple.item1.createdAt));
  }

  /// Memo is kind of LargeData, transferred in data structure [ImageTransmission]
  /// +------------------------------------------------------------+
  /// |                          LargeData                         |
  /// +------------------------+----------+------------------------+
  /// | [ImageTransmission]    |   ...    |  [ImageTransmission]   |
  /// +------------------------+----------+------------------------+
  @visibleForTesting
  Future<Tuple2<MemoInfo, Uint8List>> importImageData(void progress(int)) async {
    var info = await getLargeDataInfo();
    if (info.sizeInByte <= ImageTransmission.EMPTY_LENGTH) throw Exception('No memo');
    
    // TODO LargeData with multiple [ImageTransmission]
    var imageTransmission = await _requestTransmission(info.sizeInByte, progress);
    return Tuple2(info, imageTransmission.imageData);
  }

  @override
  List<NotePenPointer> parseSyncData(Uint8List value) {
    return adjustPointer(parseSyncPointer(value));
  }

  @visibleForTesting
  List<NotePenPointer> parseMemo(Uint8List bytes, int createdAt) {
    return adjustPointer(parseMemoPointers(bytes, createdAt));
  }

  List<NotePenPointer> parseMemoPointers(Uint8List bytes, int createdAt) {
    var byteParts = partition(bytes, 6);
    var start = createdAt;
    return byteParts.map((byteList) {
      var byteData = Uint8List.fromList(byteList).buffer.asByteData();
      if (byteList[4] == 0xFF && byteList[5] == 0xFF) {
        start = byteData.getUint32(0, Endian.little);
        return NotePenPointer(65535, 65535, 0, 0);  // adjust中会过滤掉的
      } else {
        var x = byteData.getUint16(0, Endian.little);
        var y = byteData.getUint16(2, Endian.little);
        var p = byteData.getUint16(4, Endian.little);
        return NotePenPointer(x, y, start += SAMPLE_INTERVAL_MS, p);
      }
    }).toList();
  }

  List<NotePenPointer> adjustPointer(List<NotePenPointer> pointers) {
    pointers.removeWhere((element) =>
    element.x < woodemiType.originX || element.x > woodemiType.width ||
        element.y < woodemiType.originY || element.y > woodemiType.height);

    return pointers.map((pointer) {
      var originX = ((woodemiType.originX + pointer.x) *
          woodemiType.sizeScale()).toInt();
      var originY = ((woodemiType.originY + pointer.y) *
          woodemiType.sizeScale()).toInt();
      var originP = (pointer.p * woodemiType.pressureScale()).toInt();
      return NotePenPointer(originX, originY, pointer.t, originP);
    }).toList();
  }

  @override
  Future<void> setPingInterval(int millis) async {
    var enable = millis > 0 ? 0x01 : 0x00;
    var byteData = ByteData(5)
      ..setUint8(0, 0x11)
      ..setUint8(1, 0x04)
      ..setUint8(2, enable)
      ..setUint16(3, millis, Endian.little);
    await notepadType
        .executeCommand(WoodemiCommand(request: byteData.buffer.asUint8List()));
  }

  @override
  Future<void> setSyncfrequencyInterval(int count) async {
    var byteData = ByteData(5)
      ..setUint8(0, 0x11)
      ..setUint8(1, 0x03)
      ..setUint8(2, count)
      ..setUint8(3, 0x10)
      ..setUint8(4, 0x02);
    await notepadType
        .executeCommand(WoodemiCommand(request: byteData.buffer.asUint8List()));
  }

  /// +---------------------------------+
  /// |       [ImageTransmission]       |
  /// +----------+-----------+----------+
  /// |  block   |    ...    |   block  |
  /// +----------+-----------+----------+
  Future<ImageTransmission> _requestTransmission(int totalSize, void progress(int)) async {
    var data = Uint8List.fromList([]);
    while (data.length < totalSize) {
      var currentPos = data.length;
      var blockOffset = 0;
      Map<int, Uint8List> blockChunkMap = await _requestForNextBlock(currentPos, totalSize).fold(Map<int, Uint8List>(), (acc, value) {
        blockOffset += value.item2.length;
        if (progress != null) progress((currentPos + blockOffset) * 100 ~/ totalSize);
        acc[value.item1] = value.item2;
        return acc;
      });
      var sortedKeys = blockChunkMap.keys.toList()..sort();
      var block = sortedKeys.map((k) => blockChunkMap[k]).reduce((acc, bytes) => Uint8List.fromList(acc + bytes));
      print('receiveBlock size(${block.length})');
      data = Uint8List.fromList(data + block);
    }
    return ImageTransmission.forInput(data);
  }

  /// Request in file input control pipe
  /// +------------+--------------------------------------------------------------------------------------------+
  /// | requestTag |                                     requestData                                            |
  /// +------------+----------+-------------+------------+---------------+-----------------+--------------------+
  /// |            |  imageId |  currentPos |  BlockSize |  maxChunkSize |  transferMethod |  l2capChannelOrPsm |
  /// |            |          |             |            |               |                 |                    |
  /// | 1 byte     |  2 bytes |  4 bytes    |  4 bytes   |  2bytes       |  1 byte         |  2 bytes           |
  /// +------------+----------+-------------+------------+---------------+-----------------+--------------------+
  ///
  /// [maxChunkSize] not larger than (0xFFFF + 1)
  ///
  /// Response in file input data pipe
  /// +--------------------------------+
  /// |             block              |
  /// +----------+----------+----------+
  /// | chunk    |   ...    |  chunk   |
  /// +----------+----------+----------+
  Stream<Tuple2<int, Uint8List>> _requestForNextBlock(int currentPos, int totalSize) {
    var maxChunkSize = notepadType.mtu - 1 /*responseTag*/ - 1 /*chunkSeqId*/;
    var maxBlockSize = maxChunkSize * (0xFF + 1); // chunkSeqId(1 byte) -> maxChunkPerBlock
    var blockSize = min(totalSize - currentPos, maxBlockSize);
    var transferMethod = 0;
    var l2capChannelOrPsm = 0x0004;

    print('requestForNextBlock currentPos $currentPos, totalSize $totalSize, blockSize, $blockSize, maxChunkSize $maxChunkSize');

    var imageId = fileInfo.item1;
    var byteData = ByteData(imageId.length + 4 + 4 + 2 + 1 + 2);
    var position = 0;
    for (var b in imageId)
      byteData.setInt8(position++, b);
    byteData.setUint32(position, currentPos, Endian.little);
    byteData.setUint32(position += 4, blockSize, Endian.little);
    byteData.setUint16(position += 4, maxChunkSize, Endian.little);
    byteData.setUint8(position += 2, transferMethod);
    byteData.setUint16(position += 1, l2capChannelOrPsm, Endian.little);
    var request = Uint8List.fromList([0x04] + byteData.buffer.asUint8List());

    var indexedChunkStream = _receiveChunks(chunkCountCeil(blockSize, maxChunkSize, currentPos));

    notepadType.sendRequestAsync('FileInputControl', fileInputControlRequestCharacteristic, request);

    return indexedChunkStream;
  }

  /*
   * 计算数量，
   * 如果是A1，关系式为：blockSize = n*242
   * 如果是A2，关系式为：blockSize = 64 + n*242 + 8
   */
  int chunkCountCeil(int blockSize, int maxChunkSize, int currentPos) {
    var chunkCountCeil = (blockSize / maxChunkSize).ceil();
    if (woodemiType == WoodemiType.REALTAK_CN) {
      chunkCountCeil = 256;
      if (currentPos == 0) {
        var count = ((blockSize - 64 - 8) / maxChunkSize).ceil();
        if (count <= 254) chunkCountCeil = count + 2;
      } else {
        var count = ((blockSize - 8) / maxChunkSize).ceil();
        if (count <= 255) chunkCountCeil = count + 1;
      }
    }
    print('chunkCountCeil = $chunkCountCeil');
    return chunkCountCeil;
  }

  /// +-------------+--------------------------+
  /// | responseTag |       responseData       |
  /// +-------------+-------------+------------+
  /// |             |  chunkSeqId |  chunkData |
  /// |             |             |            |
  /// | 1 byte      |  1 byte     |  ...       |
  /// +-------------+-------------+------------+
  Stream<Tuple2<int, Uint8List>> _receiveChunks(int count) => notepadType.receiveFileInput()
    .where((value) => value.first == 0x05)
    // TODO Take with timeout
    .take(count)
    .map((value) => Tuple2(value[1], value.sublist(2)));

  @override
  Future<void> deleteMemo() async {
    await notepadType.sendRequestAsync('FileInputControl', fileInputControlRequestCharacteristic, Uint8List.fromList([0x06, 0x00, 0x00, 0x00]));
    // FIXME Deal with 0x01 as notification instead of response
    await Future.delayed(Duration(milliseconds: 200));
  }
  //#endregion

  //#region Version
  @override
  Future<VersionInfo> getVersionInfo() async {
    final command = WoodemiCommand(
      request: Uint8List.fromList([0x08, 0x00]),
      intercept: (value) => value.first == 0x09,
      handle: (value) {
        final data = value.sublist(1);
        final hardware = Version(data[1], data[2]);
        final software = Version(data[3], data[4], data[5]);
        return VersionInfo(hardware: hardware, software: software);
      },
    );
    return await notepadType.executeCommand(command);
  }

  _IntCallback upgradeProgress;

  @override
  Future<void> upgrade(Uint8List upgradeBlob, Version version, void progress(int)) async {
    if (getDeviceType() == 'A2') {
      if (Platform.isAndroid) {
        upgradeProgress = progress;

        var documentsDir = await getApplicationDocumentsDirectory();
        var file = File('${documentsDir.path}/${version.description}.bin');
        await file.writeAsBytes(upgradeBlob);
        print('====================   大小：${upgradeBlob.length}');
        print('====================   路径：${file.path}');
        print('====================   设备：${scanResult.deviceId}');
        await NotepadCorePlatform.instance.methodChannel().invokeMethod('startUpgradeA2', {
          'deviceAddress': scanResult.deviceId,
          'filePath': file.path,
        });
      }
      return;
    }

    final fileData = await parseUpgradeBlob(upgradeBlob);
    final imageId = hex.decode('0100');
    final imageVersion = Uint8List.fromList(version.bytes.reversed.toList() + hex.decode('4111111101'));
    final imageData = ImageTransmission.forOutput(imageId, imageVersion, fileData).bytes;
    var lengthData = ByteData(4)..setUint32(0, imageData.length, Endian.little);
    var request = [0x03] + imageId + imageVersion + lengthData.buffer.asUint8List();

    notepadType.sendRequestAsync('FileOutputControl', fileOutputControlRequestCharacteristic, Uint8List.fromList(request));

    while (true) {
      // TODO Timeout
      var receivedRequest = await notepadType.receiveResponseAsync('FileOutputControl', fileOutputControlResponseCharacteristic, (value) => true);
      if (receivedRequest.first == 0x04) {
        final chunks = _parseChunks(receivedRequest, imageData);
        _sendChunks(chunks, (totalOffset) {
          if (progress != null) progress(100 * totalOffset ~/ imageData.length);
        });
      } else if (receivedRequest.first == 0x06) {
        if (receivedRequest[3] != 0x00) throw AssertionError('Data CRC fail');
        break;
      } else if (receivedRequest[0] == 0x07 && receivedRequest[1] == 0x05) {
        // [0x07, 0x05, 0x0b] Notepad error when parsing chunks
        print('Error receivedRequest: ${hex.encode(receivedRequest)}');
      } else {
        print('Unknown receivedRequest ${hex.encode(receivedRequest)}');
      }
    }
  }

  Iterable<Chunk> _parseChunks(Uint8List receivedRequest, Uint8List imageData) sync* {
    final byteData = receivedRequest.buffer.asByteData();
    var position = 0;
    position++; // skip request tag
    position += 2; // skip imageId
    final currentPos = byteData.getUint32(position, Endian.little);
    final blockSize = byteData.getUint32(position += 4, Endian.little);
    final maxChunkSize = byteData.getUint16(position += 4, Endian.little);
    print('receivedRequest currentPos $currentPos, blockSize $blockSize, maxChunkSize $maxChunkSize');

    final chunkCount = (blockSize / maxChunkSize).ceil();
    for (var i = 0; i < chunkCount; i++) {
      final blockOffset = i * maxChunkSize;
      final chunkSize = min(blockSize - blockOffset, maxChunkSize);
      final rangeStart = currentPos + blockOffset;
      final rangeEnd = rangeStart + chunkSize;
      yield Chunk(i, rangeStart, rangeEnd, imageData.sublist(rangeStart, rangeEnd));
    }
  }

  Future<void> _sendChunks(Iterable<Chunk> chunks, void offSetListener(int)) async {
    var iterator = chunks.iterator..moveNext();
    while (true) {
      final c = iterator.current;
      print('sendChunks ${c.index}, ${c.rangeStart}, ${c.rangeEnd}, ${c.bytes.length}');
      var chunkData = Uint8List.fromList([0x05, c.index] + c.bytes);
      try {
        await notepadType.sendRequestAsync('FileOutput', fileOutputCharacteristic, chunkData, BleOutputProperty.withoutResponse);
      } on Exception catch (e) {
        print('sendRequestAsync error: $e');
        return;
      }
      offSetListener(c.rangeEnd);
      if (iterator.moveNext()) {
        await Future.delayed(Duration(milliseconds: DEVICE_PROCESSING_INTERVAL));
      } else {
        break;
      }
    }
  }
  //#endregion
}

class Chunk {
  final int index;
  final int rangeStart;
  final int rangeEnd;
  final Uint8List bytes;

  Chunk(this.index, this.rangeStart, this.rangeEnd, this.bytes);
}