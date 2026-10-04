// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sams_mobile_app/main.dart';
import 'package:sams_mobile_app/services/app_provider.dart';

void main() {
  testWidgets('EduNexus App launch smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const SAMSApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
