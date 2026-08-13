import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pwa_app/core/theme.dart';
import 'package:pwa_app/screens/web/admin/audit_trail_panel.dart';

void main() {
  testWidgets('renders its header, the failures filter and a loading state',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: AuditTrailPanel()),
      ),
    );
    await tester.pump();

    expect(find.text('Registro de auditoría'), findsOneWidget);
    expect(find.text('Sólo fallas'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('the failures filter starts off', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: AuditTrailPanel()),
      ),
    );
    await tester.pump();

    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
  });
}
