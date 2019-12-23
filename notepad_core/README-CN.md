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
- 接收实时笔迹
- 导入离线字迹
- 获取设备信息
- 升级设备固件
- 响应设备事件

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

var authToken = null;
notepadConnector.connect(result, authToken);
// ...
notepadConnector.disconnect();
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

## 接收实时笔迹

### NotepadClient#setMode

- NotepadMode.Common

    设备仅保存压力>0的`NotePenPointer`（含时间戳）到**离线字迹**中

- NotepadMode.Sync

    设备发送所有`NotePenPointer`（无时间戳）到连接的**手机/Pad**上

设备默认为`NotepadMode.Common`（连接/未连接），只有连接后`setMode`才会更改

```dart
await _notepadClient.setMode(NotepadMode.Sync);
print('setMode complete');
```

### NotepadClientCallback#handlePointer

当`NotepadMode.Sync`时，接收`NotePenPointer`

```dart
_notepadClient.callback = this;

@override
  void handlePointer(List<NotePenPointer> list) {
    print('handlePointer ${list.length}');
  }
}
```

## 导入离线字迹

`离线字迹`保存于`NotepadMode.Common`。`离线字迹`由压力>0的`NotePenPointer`（含时间戳）组成

`离线字迹`保存在*FIFO*队列中。通常我们先获取队列摘要，然后循环导入各个`离线字迹` 

### 获取队列摘要

#### NotepadClient#getMemoSummary

获取队列的数量、占用空间等

```dart
var memoSummary = await _notepadClient.getMemoSummary();
print('getMemoSummary $memoSummary');
```

### 导入单个离线笔迹

#### NotepadClient#getMemoInfo

获取*FIFO*队列中第一个`离线笔迹`的信息

```dart
var memoInfo = await _notepadClient.getMemoInfo();
print('getMemoInfo $memoInfo');
```

#### NotepadClient#importMemo

导入*FIFO*队列中第一个`离线笔迹`

```dart
await _notepadClient.importMemo((progress) => print('progress $progress'));
```

#### NotepadClient#deleteMemo

删除*FIFO*队列中第一个`离线笔迹`

```dart
await _notepadClient.deleteMemo();
print('deleteMemo complete');
```

## 获取设备信息

### 笔迹范围

```dart
print('Size: ${_notepadClient.getDeviceSize()}')
```

### 设备名称

```dart
var name = await _notepadClient.getDeviceName();
print('getDeviceName $name');

await _notepadClient.setDeviceName('name');
print('setDeviceName complete');
```

### 电量信息

```dart
var batteryInfo = await _notepadClient.getBatteryInfo();
print('getBatteryInfo $batteryInfo');
```

### 设备时钟

```dart
var timestamp = await _notepadClient.getDeviceDate();
print('getDeviceDate $date');

await _notepadClient.setDeviceDate(timestamp);
print('setDeviceDate complete');
```

### 设备自动休眠时长

```dart
var duration = await _notepadClient.getAutoLockTime();

await _notepadClient.setAutoLockTime(duration);
print('setAutoLockTime complete');
```

## 升级设备固件

使用`*.srec`文件升级设备固件

```dart
await _notepadClient.upgrade(blob, version, (progress) {
    print("upgrade progress $progress");
});
```