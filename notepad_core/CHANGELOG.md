## [1.4.0+1] - 2020-2-27
- Fix CHANGELOG.md

## [1.4.0] - 2020-2-26
- Add `notepad_core_macos` for MacOS

## [1.3.2+2] - 2020-2-24
- Fix iOS：BOOL(YES/NO)

## [1.3.2+1] - 2020-2-21
- Fix iOS：YES/NO
- Fix nil peripheral on iOS
- Refactor uuidStr & some log

## [1.3.1+2] - 2020-1-4
- Fix pending wait in `WoodemiClient#_checkAccess`

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