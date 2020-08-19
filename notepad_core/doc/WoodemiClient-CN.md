# NXP升级协议

## 镜像传输头

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

NXP升级镜像文件的ID

```dart
// ImageTransaction#formatHeader()
final fileId = hex.decode('1EF11E0B');
```

**headerVersion**

NXP升级协议头的版本号

```dart
// ImageTransaction#formatHeader()
final headerVersion = hex.decode('0001');
```

**headerLength**

NXP升级协议头的长度

```dart
// ImageTransaction#formatHeader()
final headerLengthData = ByteData(2)..setUint16(0, HEADER_LENGTH, Endian.little);
```

**fieldControl**

NXP升级协议的控制参数

```dart
// ImageTransaction#formatHeader()
final fieldControl = hex.decode('0000');
```

**companyId**

NXP客户的公司代码

```dart
// ImageTransaction#formatHeader()
final companyId = hex.decode('FF01');
```

**imageId**

NXP镜像文件中的镜像ID

ID of image in image file

```dart
// WoodemiClient#upgrade()
final imageId = hex.decode('0100');
```

**imageVersion**

镜像版本号

```dart
// WoodemiClient#upgrade()
final imageVersion = Uint8List.fromList(version.bytes.reversed.toList() + hex.decode('4111111101'));
```

**headerString**

协议头的描述字段

```dart
// ImageTransaction#formatHeader()
var str = utf8.encode('FSL BLE OTAP Demo Image File');
    final headerString = Uint8List.fromList(List.filled(32, 0x00)
      ..setRange(0, str.length, str));
```

**totalSize**

传输总长度，包括`传输头`、`镜像数据TLV`、`映射数据TLV`、`CRC数据TLV`

```dart
// ImageTransaction#formatHeader()
final l = HEADER_LENGTH
        + (LongTagValue.HEADER_LENGTH + imageDataLength)
        + (LongTagValue.HEADER_LENGTH + bitmapDataLength)
        + (LongTagValue.HEADER_LENGTH + 2 /*crc*/);
    var totalSizeData = ByteData(4)..setUint32(0, l, Endian.little);
```

## ImageTransission Data

- 镜像数据: LongTagValue
- 映射数据: LongTagValue（可选）

`ImageTransimission.forOutput` 有映射数据, `ImageTransimission.forInput`没有.

**LongTagValue**

- 标识: 2 bytes
- 长度: 4 bytes
- 数据段: `长度`个 bytes

## ImageTransission CRC

- CRC数据: LongTagValue

> `CRC数据`使用2个bytes长度`数据段`的LongTagValue

`ImageTransimission.forOutput`查验头数据、镜像数据、映射数据

```dart
// ImageTransmission#forOutput()
var dataToCheck = _headerData + LongTagValue(TAG_IMAGE, imageData).bytes + LongTagValue(TAG_BITMAP, _bitmapData).bytes;
    _crc = crc16(Uint8List.fromList(dataToCheck));
```

`ImageTransimission.forInput`查验镜像数据

```dart
// ImageTransmission#forInput()
_imageData = longValues.firstWhere((lv) => listEquals(lv.tag, TAG_IMAGE)).value;
// ...
if (!listEquals(crc16(_imageData), _crc)) throw Exception('Data CRC fail');
```