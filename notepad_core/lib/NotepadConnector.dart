import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:notepad_core_platform_interface/notepad_core_platform_interface.dart';

import 'Notepad.dart';
import 'NotepadClient.dart';
import 'models.dart';
import 'NotepadType.dart';

typedef BluetoothChangeHandler = void Function(BluetoothState state);

typedef ConnectionChangeHandler = void Function(NotepadClient client, NotepadConnectionState state);

final notepadConnector = NotepadConnector._();

final _tag = 'NotepadConnector';

class NotepadConnector {
  NotepadConnector._() {
    NotepadCorePlatform.instance.messageHandler = _handleMessage;
  }

  Future<bool> isBluetoothAvailable() => NotepadCorePlatform.instance.isBluetoothAvailable();

  Future<dynamic> requestDevice() {
    if (!kIsWeb) throw UnimplementedError('Web platform only for now');

    return NotepadCorePlatform.instance.requestDevice(optionalServices: NotepadClient.optionalServiceCollection);
  }

  void startScan() {
    if (kIsWeb) throw UnimplementedError('Native platform only for now');

    NotepadCorePlatform.instance.startScan();
  }

  void stopScan() {
    if (kIsWeb) throw UnimplementedError('Native platform only for now');

    NotepadCorePlatform.instance.stopScan();
  }

  Stream<NotepadScanResult> get scanResultStream {
    if (kIsWeb) throw UnimplementedError('Native platform only for now');

    return NotepadCorePlatform.instance.scanResultStream
      .map((item) => NotepadScanResult.fromMap(item))
      .where(NotepadClient.support);
  }

  NotepadClient _notepadClient;
  NotepadType _notepadType;

  void connect(scanResult, [Uint8List authToken]) {
    _notepadClient = NotepadClient.create(scanResult);
    _notepadClient.setAuthToken(authToken);
    _notepadType = NotepadType(_notepadClient);
    NotepadCorePlatform.instance.connect(scanResult, _notepadClient.services);
  }

  void disconnect() {
    _clean();
    NotepadCorePlatform.instance.disconnect();
  }

  BluetoothChangeHandler bluetoothChangeHandler;

  ConnectionChangeHandler connectionChangeHandler;

  Future<void> _handleMessage(NotepadCoreMessage message) async {
    print('$_tag _handleMessage $message');
    if (message is NotepadConnectionState) {
      await _handleConnectionState(message);
    } else if (message is BluetoothState) {
      if (bluetoothChangeHandler != null) bluetoothChangeHandler(message);
    }
  }

  Future<void> _handleConnectionState(NotepadConnectionState connectionState) async {
    if (connectionState == NotepadConnectionState.connected) {
      try {
        await _notepadType.configCharacteristics();
        await _notepadClient.completeConnection((awaitConfirm) {
          if (connectionChangeHandler != null) connectionChangeHandler(_notepadClient, NotepadConnectionState.awaitConfirm);
        });
        if (connectionChangeHandler != null) connectionChangeHandler(_notepadClient, NotepadConnectionState.connected);
      } on AccessException {
        _clean();
      }
    } else if (connectionState == NotepadConnectionState.disconnected) {
      _clean();
      if (connectionChangeHandler != null) connectionChangeHandler(_notepadClient, NotepadConnectionState.disconnected);
    } else {
      if (connectionChangeHandler != null) connectionChangeHandler(_notepadClient, connectionState);
    }
  }

  // FIXME Listen to connection change
  void _clean() {
    _notepadClient?.clear();
    _notepadClient = null;
    _notepadType = null;
  }
}
