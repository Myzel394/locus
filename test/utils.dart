import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void setupFlutterLogs(final WidgetTester tester) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel("flutter_logs"),
    (call) async {
      if (call.method == "logThis") {
        print(
          "{${call.arguments['tag']}}  {${call.arguments['subTag']}}  {${call.arguments['logMessage']}}  {${DateTime.now().toIso8601String()}  {${call.arguments['level']}}",
        );
      }

      return "";
    },
  );
}
