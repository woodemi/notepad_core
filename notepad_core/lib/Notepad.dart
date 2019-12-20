import 'dart:typed_data';

import 'package:flutter/foundation.dart';

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