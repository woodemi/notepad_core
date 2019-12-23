## [1.3.0] - 2019-12-23

### NotepadCorePlugin

- Impl `requestMtu`
- Impl `requestConnectionPriority`
- Impl `writeValue` with optional `BleOutputProperty`

## [1.2.1] - 2019-12-21

- Fix `addEventListener` in `Bluetooth` when release

## [1.2.0] - 2019-12-21

### NotepadCorePlugin

- Implement `isBluetoothAvailable`
- Implement `BluetoothState` notification

## [1.1.0] - 2019-12-20

### NotepadCorePlugin

#### Operate service/characteristic
- Implement `readValue`
- Implement `inputValueStream`

## [1.0.0] - 2019-12-19

### NotepadCorePlugin

#### Scan/Request device
- Implement `requestDevice`

#### Connect/Disconnect device
- Implement `connect`, `disconnect`
- Notify `messageHandler` when connection state change

#### Operate service/characteristic
- Implement `setNotifiable`
- Implement `writeValue`