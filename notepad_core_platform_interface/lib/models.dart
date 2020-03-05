const GSS_SUFFIX = "0000-1000-8000-00805f9b34fb";

typedef MessageHandler = Future<dynamic> Function(NotepadCoreMessage message);

class NotepadCoreMessage {
  const NotepadCoreMessage._();
}

class BluetoothState extends NotepadCoreMessage {
  static const available = BluetoothState._('available');
  static const unavailable = BluetoothState._('unavailable');

  final String value;

  const BluetoothState._(this.value) : super._();

  static BluetoothState parse(String value) {
    if (value == available.value) {
      return available;
    } else if (value == unavailable.value) {
      return unavailable;
    }
    throw ArgumentError.value(value);
  }
}

class NotepadConnectionState extends NotepadCoreMessage {
  static const disconnected = NotepadConnectionState._('disconnected');
  static const connecting = NotepadConnectionState._('connecting');
  static const awaitConfirm = NotepadConnectionState._('awaitConfirm');
  static const connected = NotepadConnectionState._('connected');

  final String value;

  const NotepadConnectionState._(this.value) : super._();

  static NotepadConnectionState parse(String value) {
    if (value == disconnected.value) {
      return disconnected;
    } else if (value == connecting.value) {
      return connecting;
    } else if (value == connected.value) {
      return connected;
    }
    throw ArgumentError.value(value);
  }
}
