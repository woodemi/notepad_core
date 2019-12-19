import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:notepad_core_platform_interface/notepad_core_platform_interface.dart';

const _method = const MethodChannel('notepad_core/method');
const _event_scanResult = const EventChannel('notepad_core/event.scanResult');
const _message_connector = BasicMessageChannel('notepad_core/message.connector', StandardMessageCodec());

class MethodChannelNotepadCore extends NotepadCorePlatform {
  MethodChannelNotepadCore() {
    _message_connector.setMessageHandler(_handleConnectorMessage);
  }

  @override
  Future<dynamic> requestDevice() {
    throw UnimplementedError('Not implemented in MethodChannelNotepadCore');
  }

  @override
  void startScan() {
    _method
        .invokeMethod('startScan')
        .then((_) => print('startScan invokeMethod success'));
  }

  @override
  void stopScan() {
    _method
        .invokeMethod('stopScan')
        .then((_) => print('stopScan invokeMethod success'));
  }

  Stream<dynamic> _scanResultStream = _event_scanResult.receiveBroadcastStream({'name': 'scanResult'});

  @override
  Stream<dynamic> get scanResultStream => _scanResultStream;

  @override
  void connect(scanResult) {
    _method.invokeMethod('connect', {
      'deviceId': scanResult.deviceId,
    }).then((_) => print('connect invokeMethod success'));
    if (messageHandler != null) messageHandler(ConnectionState.connecting);
  }

  @override
  void disconnect() {
    _method.invokeMethod('disconnect').then((_) {
      print('disconnect invokeMethod success');
    });
  }

  Future<dynamic> _handleConnectorMessage(dynamic message) async {
    print('_handleConnectorMessage $message');
    if (message['ConnectionState'] != null) {
      var connectionState = ConnectionState.parse(message['ConnectionState']);
      if (messageHandler != null) messageHandler(connectionState);
    }
  }

  @override
  Future<void> writeValue(Tuple2<String, String> serviceCharacteristic, Uint8List value) {
    // TODO: implement writeValue
    return null;
  }
}