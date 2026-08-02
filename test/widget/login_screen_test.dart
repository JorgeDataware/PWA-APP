import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pwa_app/core/theme.dart';
import 'package:pwa_app/providers/auth_provider.dart';
import 'package:pwa_app/screens/auth/login_screen.dart';

void main() {
  Widget wrap() => ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(),
        child: MaterialApp(theme: AppTheme.dark, home: const LoginScreen()),
      );

  group('LoginScreen', () {
    testWidgets('renders the email and password fields plus a submit button', (tester) async {
      await tester.pumpWidget(wrap());

      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Contraseña'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Iniciar sesión'), findsOneWidget);
    });

    testWidgets('shows validation errors and does not attempt login when fields are empty', (tester) async {
      await tester.pumpWidget(wrap());

      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
      await tester.pump();

      expect(find.text('Requerido'), findsNWidgets(2));
    });

    testWidgets('offers a way to browse news without creating an account', (tester) async {
      await tester.pumpWidget(wrap());

      expect(find.widgetWithText(TextButton, 'Explorar noticias sin cuenta'), findsOneWidget);
    });
  });
}
