import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:notepad_core_platform_interface/notepad_core_platform_interface.dart';

import 'notepad_core_platform_interface.dart';

const _method = const MethodChannel('notepad_core/method');
const _event_scanResult = const EventChannel('notepad_core/event.scanResult');
const _message_connector = BasicMessageChannel('notepad_core/message.connector', StandardMessageCodec());

class MethodChannelNotepadCore extends NotepadCorePlatform {
  MethodChannelNotepadCore() {
    _message_connector.setMessageHandler(_handleConnectorMessage);
  }

  @override
  Future<dynamic> requestDevice({
    List<String> optionalServices,
  }) {
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
      if (connectionState == ConnectionState.connected) {
        _method.invokeMethod('discoverServices').then((_) => print('discoverServices invokeMethod success'));
      } else {
        if (messageHandler != null) messageHandler(connectionState);
      }
    } else if (message['ServiceState'] != null) {
      if (message['ServiceState'] == 'discovered')
        if (messageHandler != null) messageHandler(ConnectionState.connected);
    }
  }

  @override
  Future<void> writeValue(Tuple2<String, String> serviceCharacteristic, Uint8List value) async {
    _method.invokeMethod('writeValue', {
      'service': serviceCharacteristic.item1,
      'characteristic': serviceCharacteristic.item2,
      'value': value,
    }).then((_) {
      print('writeValue invokeMethod success');
    }).catchError((onError) {
      // Characteristic sometimes unavailable on Android
      throw onError;
    });
  }
}