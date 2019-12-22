[English](./README.md) | 简体中文

# notepad_core
连接并操作智能手写本的Flutter插件

- [36记智能手写本](https://www.36notes.com)
- [磐度智能书写本](http://www.pendo-tech.com/zh-cn/product/a5) TODO
- [和冠智能笔记本](https://www.wacom.com/en-us/products/smartpads) TODO

# 功能
- 扫描设备
- 连接设备
- 绑定设备

## 扫描设备

### Android/iOS

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

连接从`notepadConnector.scanResultStream`中扫描到的`result`， 

参数`authToken`可选，不传则默认为`[0x00, 0x00, 0x00, 0x01]`

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

## 绑定设备

用`NotepadConnector#connect`的`authToken`绑定设备

```dart
await _notepadClient.claimAuth();
print('claimAuth success');
// ...
await _notepadClient.disclaimAuth();
print('disclaimAuth success');
```