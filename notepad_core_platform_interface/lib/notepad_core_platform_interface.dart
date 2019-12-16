library notepad_core_platform_interface;

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel_notepad_core.dart';

abstract class NotepadCorePlatform extends PlatformInterface {
  NotepadCorePlatform() : super(token: _token);

  static final Object _token = Object();

  static NotepadCorePlatform _instance = MethodChannelNotepadCore();

  static NotepadCorePlatform get instance => _instance;

  static set instance(NotepadCorePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<dynamic> requestDevice();

  void startScan();

  void stopScan();
}