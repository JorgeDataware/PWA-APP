import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pwa_app/core/theme.dart';
import 'package:pwa_app/screens/legal/terms_screen.dart';

void main() {
  group('TermsScreen', () {
    testWidgets('renders the heading and the last-updated date', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.dark, home: const TermsScreen()),
      );
      await tester.pump();

      // Title appears twice: in the AppBar and as the page heading.
      expect(find.textContaining('Términos y condiciones'), findsWidgets);
      expect(find.textContaining('Última actualización'), findsOneWidget);
    });

    testWidgets('covers the sections a terms document is expected to have', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.dark, home: const TermsScreen()),
      );
      await tester.pump();

      // Scroll-independent check: the section titles all exist in the tree
      // even if they're below the fold in this viewport.
      for (final section in const [
        '1. Aceptación de los términos',
        '4. Uso aceptable',
        '5. Propiedad intelectual',
        '8. Limitación de responsabilidad',
        '11. Tratamiento de datos personales',
        '13. Legislación aplicable',
      ]) {
        expect(find.text(section), findsOneWidget, reason: 'falta la sección "$section"');
      }
    });
  });
}
