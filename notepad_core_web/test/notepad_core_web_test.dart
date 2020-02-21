import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notepad_core_web/notepad_core_web.dart';

void main() {
  const MethodChannel channel = MethodChannel('notepad_core_web');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await NotepadCoreWeb.platformVersion, '42');
  });
}
