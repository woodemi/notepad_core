import 'package:flutter/foundation.dart';

bool startWith<T>(List<T> src, List<T> prefix) =>
    src.length >= prefix.length &&
    listEquals(src.take(prefix.length).toList(), prefix);
