import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';

import '../Notepad.dart';

const SUFFIX = 'ba5e-f4ee-5ca1-eb1e5e4b1ce0';

const SERV__COMMAND = '57444d01-$SUFFIX';
const CHAR__COMMAND_REQUEST = '57444e02-$SUFFIX';
const CHAR__COMMAND_RESPONSE = CHAR__COMMAND_REQUEST;

const SERV__SYNC = '57444d06-$SUFFIX';
const CHAR__SYNC_INPUT = '57444d07-$SUFFIX';

const SERV__FILE_INPUT = '57444d03-$SUFFIX';
const CHAR__FILE_INPUT_CONTROL_REQUEST = '57444d04-$SUFFIX';
const CHAR__FILE_INPUT_CONTROL_RESPONSE = CHAR__FILE_INPUT_CONTROL_REQUEST;
const CHAR__FILE_INPUT = '57444d05-$SUFFIX';

const SERV__FILE_OUTPUT = '01ff5550-$SUFFIX';
const CHAR__FILE_OUTPUT_CONTROL_REQUEST = '01ff5551-$SUFFIX';
const CHAR__FILE_OUTPUT_CONTROL_RESPONSE = CHAR__FILE_OUTPUT_CONTROL_REQUEST;
const CHAR__FILE_OUTPUT = '01ff5552-$SUFFIX';

final defaultAuthToken = Uint8List.fromList([0x00, 0x00, 0x00, 0x01]);

const MTU_WUART = 247;

/**
 * +---A1P--+
 * |        |
 * |  +A1+  |
 * |  |  |  |
 * |  |  |  |
 * |  +--+  |
 * |        |
 * +--------+
 */
class WoodemiType {
  //  A1(国内版本)
  static final UGEE_CN = WoodemiType._([0x41, 0x35], 'A1', 0, 0, 14800, 21000, 512);

  //  A1(国际版本)
  static final UGEE_GLOBAL = WoodemiType._([0x41, 0x36], 'A1', 0, 0, 14800, 21000, 512);

  //  A1 Pro(国内版本)
  static final EMRIGHT_CN = WoodemiType._([0x41, 0x37], 'A1 Pro', -500, 0, 14800, 21000, 2048);

  //  A2（国内版本）
  static final REALTAK_CN = WoodemiType._([0x41, 0x39], 'A2', 0, 0, 14800, 21000, 2048);

  final List<int> type;
  final String deviceType;
  final int originX;
  final int originY;
  final int width;
  final int height;
  final int pressure;

  WoodemiType._(this.type, this.deviceType, this.originX, this.originY, this.width, this.height, this.pressure);

  double sizeScale() => 14800.0 / width;

  double pressureScale() => 512.0 / pressure;
}

const SAMPLE_INTERVAL_MS = 5;

const DEVICE_PROCESSING_INTERVAL = 110;

class WoodemiCommand<T> extends NotepadCommand<T> {
  WoodemiCommand({
    @required Uint8List request,
    Predicate intercept,
    Handle<T> handle,
  }) : super(
    request: request,
    intercept: intercept ?? defaultIntercept(request),
    handle: handle ?? defaultHandle,
  );

  static Predicate defaultIntercept(Uint8List request) {
    return (value) => value[0] == 0x07 && value[1] == request.first;
  }

  static final Handle<void> defaultHandle = (response) {
    if (response[4] != 0x00) throw Exception('WOODEMI_COMMAND fail: response ${hex.encode(response)}');
  };
}