import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pwa_app/widgets/app_footer.dart';

// NOTE: a true full-app boot smoke test (pumping TechNewsApp end to end)
// was removed from this suite. NewsListScreen's initState fires a real
// http.get with no client-side timeout (see ApiClient), and this sandbox
// silently drops outbound connections rather than refusing them — so any
// widget test that reaches that code path hangs for the full 10-minute
// per-test timeout instead of failing fast. Fix tracked as a follow-up:
// give ApiClient a request timeout and/or an injectable http.Client so
// screens can be tested without live network. See docs/pruebas/plan-de-pruebas.md.

void main() {
  testWidgets('AppFooter renders legal links, social icons and the copyright line', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AppFooter())));

    expect(find.text('Acerca de'), findsOneWidget);
    expect(find.text('Aviso de privacidad'), findsOneWidget);
    expect(find.text('Contacto'), findsOneWidget);
    expect(find.byIcon(Icons.facebook), findsOneWidget);
    expect(find.textContaining('TechNews'), findsWidgets);
  });
}
