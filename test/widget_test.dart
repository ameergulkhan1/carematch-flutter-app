import 'package:flutter_test/flutter_test.dart';
import 'package:carematch_app/app.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const CareMatchApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
