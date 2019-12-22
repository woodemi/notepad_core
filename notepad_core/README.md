English | [简体中文](./README-CN.md)

# notepad_core
Flutter plugin for connect & operate on smart notepad

- [36notes](https://www.36notes.com)
- [Pendo](http://www.pendo-tech.com) TODO
- [Wacom Smartpads](https://www.wacom.com/en-us/products/smartpads) TODO

# Usage
- Scan notepad
- Connect notepad
- Claim notepad
- Sync notepen pointer
- Get notepad info

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

var authToken = null;
notepadConnector.connect(result, authToken);
// ...
notepadConnector.disconnect();
```

## Claim notepad

Claim with `authToken`, the parameter of `NotepadConnector#connect`

```dart
await _notepadClient.claimAuth();
print('claimAuth success');
// ...
await _notepadClient.disclaimAuth();
print('disclaimAuth success');
```

## Sync notepen pointer

### NotepadClient#setMode

- NotepadMode.Common

    Notepad saves only `NotePenPointer` with positive pressure & accurate timestamp, into **offline memo** 

- NotepadMode.Sync

    Notepad notify every `NotePenPointer`, positive or not, without timestamp, to connected **mobile device**

Notepad is always `NotepadMode.Common` (connected or disconnected), unless `setMode` after connected

```dart
await _notepadClient.setMode(NotepadMode.Sync);
print('setMode complete');
```

### NotepadClientCallback#handlePointer

Receive `NotePenPointer`s in `NotepadMode.Sync`

```dart
_notepadClient.callback = this;

@override
  void handlePointer(List<NotePenPointer> list) {
    print('handlePointer ${list.length}');
  }
}
```

## Get notepad info

### Paint Size

```dart
print('Size: ${_notepadClient.getDeviceSize()}')
```

### Device Name

```dart
var name = await _notepadClient.getDeviceName();
print('getDeviceName $name');

await _notepadClient.setDeviceName('name');
print('setDeviceName complete');
```

### Battery Info

```dart
var batteryInfo = await _notepadClient.getBatteryInfo();
print('getBatteryInfo $batteryInfo');
```

### Device Date

```dart
var timestamp = await _notepadClient.getDeviceDate();
print('getDeviceDate $date');

await _notepadClient.setDeviceDate(timestamp);
println('setDeviceDate complete');
```

### Auto-Lock Time

```dart
var duration = await _notepadClient.getAutoLockTime();

await _notepadClient.setAutoLockTime(duration);
print('setAutoLockTime complete');
```
