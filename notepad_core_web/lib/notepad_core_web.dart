import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:notepad_core_platform_interface/notepad_core_platform_interface.dart';

class NotepadCorePlugin extends NotepadCorePlatform {
  static void registerWith(Registrar registrar) {
    NotepadCorePlatform.instance = NotepadCorePlugin();
  }
}
