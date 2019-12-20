typedef MessageHandler = Future<dynamic> Function(NotepadCoreMessage message);

class NotepadCoreMessage {
  const NotepadCoreMessage._();
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
