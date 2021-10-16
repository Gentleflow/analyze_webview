import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:analyze_webview/analyze_webview.dart';

void main() {
  const MethodChannel channel = MethodChannel('analyze_webview');

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
    expect(await AnalyzeWebview.platformVersion, '42');
  });
}
