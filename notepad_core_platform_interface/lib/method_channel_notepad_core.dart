import 'package:flutter/services.dart';
import 'package:notepad_core_platform_interface/notepad_core_platform_interface.dart';

const _method = const MethodChannel('notepad_core/method');

class MethodChannelNotepadCore extends NotepadCorePlatform {
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
}