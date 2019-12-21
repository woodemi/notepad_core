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