import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cinemaflix/main.dart';
import 'package:cinemaflix/widgets/app_logo.dart';

void main() {
  testWidgets('ConfigErrorApp shows the error message', (tester) async {
    await tester.pumpWidget(const ConfigErrorApp(message: 'Missing env'));
    expect(find.text('Configuration error'), findsOneWidget);
    expect(find.text('Missing env'), findsOneWidget);
  });

  testWidgets('AppLogo renders', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppLogo(size: 48))),
    );
    expect(find.byType(AppLogo), findsOneWidget);
  });
}
