import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'models.dart';

const GATT_HEADER_LENGTH = 3;

const GSS_SUFFIX = "0000-1000-8000-00805f9b34fb";
const CODE__SERV_BATTERY = "180f";
const CODE__CHAR_BATTERY_LEVEL = "2a19";

const SERV__BATTERY = "0000$CODE__SERV_BATTERY-$GSS_SUFFIX";
const CHAR__BATTERY_LEVEL = "0000$CODE__CHAR_BATTERY_LEVEL-$GSS_SUFFIX";

typedef Predicate = bool Function(Uint8List data);

typedef Handle<T> = T Function(Uint8List data);

class NotepadCommand<T> {
  final Uint8List request;
  final Predicate intercept;
  final Handle<T> handle;

  NotepadCommand({
    @required this.request,
    @required this.intercept,
    @required this.handle,
  })
      : assert(request != null),
        assert(intercept != null),
        assert(handle != null);
}

enum AccessResult {
  Denied,      // Device claimed by other user
  Confirmed,   // Access confirmed, indicating device not claimed by anyone
  Unconfirmed, // Access unconfirmed, as user doesn't confirm before timeout
  Approved     // Device claimed by this user
}

class AccessException implements Exception {
  static final Denied = AccessException._('Notepad claimed by other user');
  static final Unconfirmed = AccessException._('User does not confirm before timeout');

  final String message;

  AccessException._(this.message);
}

List<NotePenPointer> parseSyncPointer(Uint8List value) {
  var byteData = value.buffer.asByteData();
  return List.generate(value.length ~/ 6, (index) {
    return NotePenPointer(
        byteData.getUint16(index * 6, Endian.little),
        byteData.getUint16(index * 6 + 2, Endian.little),
        -1,
        byteData.getUint16(index * 6 + 4, Endian.little),
    );
  });
}