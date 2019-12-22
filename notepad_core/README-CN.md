[English](./README.md) | 简体中文

# notepad_core
连接并操作智能手写本的Flutter插件

- [36记智能手写本](https://www.36notes.com)
- [磐度智能书写本](http://www.pendo-tech.com/zh-cn/product/a5) TODO
- [和冠智能笔记本](https://www.wacom.com/en-us/products/smartpads) TODO

# 功能
- 扫描设备

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