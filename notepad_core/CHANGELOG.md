## [1.3.1+1] - 2020-1-4
- Fix NPE for `NotepadClient.callback` when `handleMessageEvent`

## [1.3.1] - 2020-1-4
- Fix missing `"disconnected"` message when call `NotepadConnector#disconnect` on Android/iOS

## [1.3.0] - 2019-12-23

### NotepadClient

#### SyncInput

- Improve speed on Android

#### ImportMemo

- Add `getMemoSummary`, `getMemoInfo`
- Add `importMemo`, `deleteMemo`

#### Versioning

- Add `getVersionInfo`, `upgrade`

#### Notepad Event

- Add `KeyEvent`, `BatteryAlertEvent`, `ChargingStatusEvent`, `StorageAlertEvent`

## [1.2.0+1] - 2019-12-22

Add [README.md](./README.md) & [README-CN.md](./README-CN.md)

## [1.2.0] - 2019-12-21

### NotepadConnector
- Add `bluetoothChangeHandler` for bluetooth state change event

### NotepadClient

#### SyncInput
- Add `setMode`
- Add `NotepadClientCallback` with `handlePointer`

## [1.1.0] - 2019-12-20

### NotepadConnector
- Add `connectionChangeHandler` for connection state change event

### NotepadClient

#### Authorization
- `connect` with authToken
- `claimAuth`, `disclaimAuth`

#### Device info
- `getDeviceSize`
- `getDeviceName`, `setDeviceName`
- `getBatteryInfo`
- `getDeviceDate`, `setDeviceDate`
- `getAutoLockTime`, `setAutoLockTime`

## [1.0.0] - 2019-12-19

### NotepadConnector

#### Scan/Request device
- `requestDevice` for Web
- `startScan`, `stopScan`, `scanResultStream` for Android/iOS

#### Connect/Disconnect device
- `connect`, `disconnect`