import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';

Future<Uint8List> parseUpgradeBlob(Uint8List blob) async {
  final lines = utf8.decode(blob).split('\r\n');
  var records = lines
      .where((l) => l.isNotEmpty)
      .map(FileRecord.fromLine)
      .where((r) => FileRecord.RECORD_TYPE_DATAs.contains(r.tag))
      .toList();

  var start = records.first.address;
  var end = records.last.address + records.last.data.length;
  var result = List.filled(end - start, 0xFF);
  for (final r in records)
    result.setRange(r.address - start, r.address - start + r.data.length, r.data);
  return Uint8List.fromList(result);
}

/// In Motorola S-records(S19) file format
/// A single line is a [FileRecord]
class FileRecord {
  static const RECORD_TYPE_HEADER = "S0"; // 16 bit address
  static const RECORD_TYPE_DATA_1 = "S1"; // 16 bit address
  static const RECORD_TYPE_DATA_2 = "S2"; // 24 bit address
  static const RECORD_TYPE_DATA_3 = "S3"; // 32 bit address
  static const RECORD_TYPE_TERMINATION = "S8"; //
  static const RECORD_TYPE_DATAs = [RECORD_TYPE_DATA_1, RECORD_TYPE_DATA_2, RECORD_TYPE_DATA_3];

  final String tag;

  final Uint8List value;

  FileRecord._(this.tag, this.value) {
    var addressBytes = value.sublist(0, addressLength);
    _address = int.parse(hex.encode(addressBytes), radix: 16);
    _data = value.sublist(addressLength);
  }

  int get addressLength {
    switch (tag) {
      case RECORD_TYPE_HEADER:
      case RECORD_TYPE_DATA_1:
      case RECORD_TYPE_TERMINATION:
        return 2;
      case RECORD_TYPE_DATA_2:
        return 3;
      case RECORD_TYPE_DATA_3:
        return 4;
      default:
        return 2;
    }
  }

  int _address;
  int get address => _address;

  Uint8List _data;
  Uint8List get data => _data;

  static FileRecord fromLine(String line) {
    final tag = line.substring(0, 2);
    final length = int.parse(line.substring(2, 4), radix: 16);
    final value = Uint8List.fromList(hex.decode(line.substring(4)));
    if (length != value.length) throw AssertionError('Invalid value size');

    var checksum = value.last;
    var list = [value.length] + value.sublist(0, value.length - 1 /*checksum*/);
    var listToCheck = Uint8List.fromList(list);
    var sum = listToCheck.reduce((acc, value) => (acc + value) & 0xFF);
    if (~sum & 0xFF != checksum) throw AssertionError('Invalid checksum');

    return FileRecord._(tag, value);
  }
}