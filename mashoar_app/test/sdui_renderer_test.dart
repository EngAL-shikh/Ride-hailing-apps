import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mashoar_app/app/core/sdui/sdui_renderer.dart';

void main() {
  testWidgets('SDUI renderer builds a text widget', (tester) async {
    const json = <String, dynamic>{
      'type': 'column',
      'children': [
        {'type': 'text', 'value': 'مرحبا'},
        {'type': 'spacer', 'height': 12},
        {
          'type': 'text',
          'value': 'MotoYemen',
          'style': {'fontSize': 18, 'fontWeight': 'bold'}
        },
      ],
    };

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SduiRenderer(json: json),
        ),
      ),
    );

    expect(find.text('مرحبا'), findsOneWidget);
    expect(find.text('MotoYemen'), findsOneWidget);
  });
}

