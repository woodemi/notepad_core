# NXP Upgrade protocol

## ImageTransaction Header

- fileId: 4 bytes
- headerVersion: 2 bytes
- headerLength: 2 bytes
- fieldControl: 2 bytes
- companyId: 2 bytes
- imageId: 2 bytes
- imageVersion: 8 bytes
- headerString: 32 bytes
- totalSize: 4 bytes

**fileId**

ID of NXP upgrade image file

```dart
// ImageTransaction#formatHeader()
final fileId = hex.decode('1EF11E0B');
```

**headerVersion**

Version of NXP upgrade protocol header

```dart
// ImageTransaction#formatHeader()
final headerVersion = hex.decode('0001');
```

**headerLength**

Length of NXP upgrade protocol header

```dart
// ImageTransaction#formatHeader()
final headerLengthData = ByteData(2)..setUint16(0, HEADER_LENGTH, Endian.little);
```

**fieldControl**

Arguments for NXP upgrade protocol

```dart
// ImageTransaction#formatHeader()
final fieldControl = hex.decode('0000');
```

**companyId**

Agent ID of NXP

```dart
// ImageTransaction#formatHeader()
final companyId = hex.decode('FF01');
```

**imageId**

ID of image in image file

```dart
// WoodemiClient#upgrade()
final imageId = hex.decode('0100');
```

**imageVersion**

Version of image

```dart
// WoodemiClient#upgrade()
final imageVersion = Uint8List.fromList(version.bytes.reversed.toList() + hex.decode('4111111101'));
```

**headerString**

Display string for image

```dart
// ImageTransaction#formatHeader()
var str = utf8.encode('FSL BLE OTAP Demo Image File');
    final headerString = Uint8List.fromList(List.filled(32, 0x00)
      ..setRange(0, str.length, str));
```

**totalSize**

Total size of the transimission, including `transimission header` & `image data TagValue` & `bitmap data TagValue` & `CRC TagValue`

```dart
// ImageTransaction#formatHeader()
final l = HEADER_LENGTH
        + (LongTagValue.HEADER_LENGTH + imageDataLength)
        + (LongTagValue.HEADER_LENGTH + bitmapDataLength)
        + (LongTagValue.HEADER_LENGTH + 2 /*crc*/);
    var totalSizeData = ByteData(4)..setUint32(0, l, Endian.little);
```

## ImageTransission Data

- Image data: LongTagValue
- Bitmap data: LongTagValue (Optional)

`ImageTransimission.forOutput` has bitmap data, `ImageTransimission.forInput` does not.

**LongTagValue**

- tag: 2 bytes
- length: 4 bytes
- data: `length` bytes

## ImageTransission CRC

- CRC data: LongTagValue

> `CRC data` fills 2 bytes into the `data` section of LongTagValue

`ImageTransimission.forOutput` checks header data & image data & bitmap data

```dart
// ImageTransmission#forOutput()
var dataToCheck = _headerData + LongTagValue(TAG_IMAGE, imageData).bytes + LongTagValue(TAG_BITMAP, _bitmapData).bytes;
    _crc = crc16(Uint8List.fromList(dataToCheck));
```

`ImageTransimission.forInput` checks image data

```dart
// ImageTransmission#forInput()
_imageData = longValues.firstWhere((lv) => listEquals(lv.tag, TAG_IMAGE)).value;
// ...
if (!listEquals(crc16(_imageData), _crc)) throw Exception('Data CRC fail');
```
