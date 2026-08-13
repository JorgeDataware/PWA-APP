import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pwa_app/core/theme.dart';
import 'package:pwa_app/screens/web/admin/admin_dashboard_screen.dart';

void main() {
  testWidgets('shows its title and a loading indicator while fetching',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const AdminDashboardScreen()),
    );
    await tester.pump();

    expect(find.text('Panel de control'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byTooltip('Actualizar'), findsOneWidget);
  });
}
