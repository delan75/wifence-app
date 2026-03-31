import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wifence_app/theme/wifence_theme.dart';

void main() {
  testWidgets('WiFence theme boots in a basic shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildWiFenceTheme(),
        home: const Scaffold(
          body: Center(
            child: Text('WiFence'),
          ),
        ),
      ),
    );

    expect(find.text('WiFence'), findsOneWidget);
  });
}
