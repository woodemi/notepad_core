English | [简体中文](./README-CN.md)

# notepad_core
Flutter plugin for connect & operate on smart notepad

- [36notes](https://www.36notes.com)
- [Pendo](http://www.pendo-tech.com) TODO
- [Wacom Smartpads](https://www.wacom.com/en-us/products/smartpads) TODO

# Usage
- Scan notepad
- Connect notepad

## Scan notepad

```dart
notepadConnector.scanResultStream.listen((result) {
    print('onScanResult $result');
});

notepadConnector.startScan();
// ...
notepadConnector.stopScan();
```

### Web

```dart
var device = notepadConnector.requestDevice();
print('requestDevice $device');
```

## Connect notepad

Connect to `result`, received from `notepadConnector.scanResultStream`

Parameter `authToken` is optional. `[0x00, 0x00, 0x00, 0x01]` will be used if missing

```dart
notepadConnector.connectionChangeHandler = _handleConnectionChange;

void _handleConnectionChange(NotepadClient client, NotepadConnectionState state) {
    print('_handleConnectionChange $client $state');
}

val authToken = null
notepadConnector.connect(context, result, authToken)
// ...
notepadConnector.disconnect()
```