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