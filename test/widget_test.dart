import 'package:caltrack/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Theme builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCalTrackTheme(),
        home: const Scaffold(body: Text('CalTrack')),
      ),
    );
    expect(find.text('CalTrack'), findsOneWidget);
  });
}
