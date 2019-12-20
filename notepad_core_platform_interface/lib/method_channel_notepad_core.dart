import 'dart:async';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:flutter/services.dart';
import 'package:notepad_core_platform_interface/notepad_core_platform_interface.dart';
import 'package:notepad_core_platform_interface/notepad_core_platform_interface.dart';

import 'notepad_core_platform_interface.dart';

const _method = const MethodChannel('notepad_core/method');
const _event_scanResult = const EventChannel('notepad_core/event.scanResult');
const _message_connector = BasicMessageChannel('notepad_core/message.connector', StandardMessageCodec());
const _message_client = BasicMessageChannel('notepad_core/message.client', StandardMessageCodec());

class MethodChannelNotepadCore extends NotepadCorePlatform {
  MethodChannelNotepadCore() {
    _message_connector.setMessageHandler(_handleConnectorMessage);
    _message_client.setMessageHandler(_handleClientMessage);
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
    if (messageHandler != null) messageHandler(NotepadConnectionState.connecting);
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
      var connectionState = NotepadConnectionState.parse(message['ConnectionState']);
      if (connectionState == NotepadConnectionState.connected) {
        _method.invokeMethod('discoverServices').then((_) => print('discoverServices invokeMethod success'));
      } else {
        if (messageHandler != null) messageHandler(connectionState);
      }
    } else if (message['ServiceState'] != null) {
      if (message['ServiceState'] == 'discovered')
        if (messageHandler != null) messageHandler(NotepadConnectionState.connected);
    }
  }

  // FIXME Close
  final _characteristicConfigController = StreamController<String>.broadcast();

  @override
  Future<void> setNotifiable(Tuple2<String, String> serviceCharacteristic) async {
    _method.invokeMethod('setNotifiable', {
      'service': serviceCharacteristic.item1,
      'characteristic': serviceCharacteristic.item2,
      'bleInputProperty': 'indication',
    }).then((_) => print('setNotifiable invokeMethod success'));
    // TODO Timeout
    await _characteristicConfigController.stream.any((c) => c == serviceCharacteristic.item2);
  }

  @override
  void readValue(Tuple2<String, String> serviceCharacteristic) {
    _method.invokeListMethod('readValue', {
      'service': serviceCharacteristic.item1,
      'characteristic': serviceCharacteristic.item2,
    }).then((_) => print('readValue invokeMethod success'));
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

  // FIXME Close
  final _characteristicValueController = StreamController<Tuple2<String, Uint8List>>.broadcast();

  @override
  Stream<Tuple2<String, Uint8List>> get inputValueStream => _characteristicValueController.stream;

  Future<dynamic> _handleClientMessage(dynamic message) {
    print('_handleClientMessage $message');
    if (message['characteristicConfig'] != null) {
      _characteristicConfigController.add(message['characteristicConfig']);
    } else if (message['characteristicValue'] != null) {
      var characteristicValue = message['characteristicValue'];
      var value = Uint8List.fromList(characteristicValue['value']); // In case of _Uint8ArrayView
      _characteristicValueController.add(Tuple2(characteristicValue['characteristic'], value));
    }
  }
}