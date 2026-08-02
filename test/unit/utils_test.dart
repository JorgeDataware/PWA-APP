import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pwa_app/core/utils.dart';

/// Renders [child] under a MediaQuery of the given [width] so we can read
/// `context.isWearable/.isMobile/.isDesktop` the same way the real widget
/// tree does, without needing a live device or browser window.
Future<BuildContext> _pumpAtWidth(WidgetTester tester, double width) async {
  late BuildContext capturedContext;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: Size(width, 800)),
      child: Builder(
        builder: (context) {
          capturedContext = context;
          return const SizedBox();
        },
      ),
    ),
  );
  return capturedContext;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es', null);
  });

  group('Breakpoints (BuildContext extensions)', () {
    testWidgets('width <= 320px is wearable', (tester) async {
      final context = await _pumpAtWidth(tester, 300);
      expect(context.isWearable, isTrue);
      expect(context.isMobile, isTrue);
      expect(context.isDesktop, isFalse);
    });

    testWidgets('width exactly at the wearable threshold (320px) counts as wearable', (tester) async {
      final context = await _pumpAtWidth(tester, 320);
      expect(context.isWearable, isTrue);
    });

    testWidgets('width between 321 and 768px is mobile, not wearable or desktop', (tester) async {
      final context = await _pumpAtWidth(tester, 500);
      expect(context.isWearable, isFalse);
      expect(context.isMobile, isTrue);
      expect(context.isDesktop, isFalse);
    });

    testWidgets('width above 768px is desktop', (tester) async {
      final context = await _pumpAtWidth(tester, 1024);
      expect(context.isWearable, isFalse);
      expect(context.isMobile, isFalse);
      expect(context.isDesktop, isTrue);
    });
  });

  group('Date formatting', () {
    test('formatDate renders a long Spanish date', () {
      final date = DateTime(2026, 6, 11);
      expect(formatDate(date), '11 jun 2026');
    });

    test('formatDateShort renders dd/MM/yy', () {
      final date = DateTime(2026, 6, 11);
      expect(formatDateShort(date), '11/06/26');
    });

    test('formatDateRelative renders minutes for very recent dates', () {
      final date = DateTime.now().subtract(const Duration(minutes: 5));
      expect(formatDateRelative(date), 'Hace 5 min');
    });

    test('formatDateRelative falls back to the long date after 7 days', () {
      final date = DateTime.now().subtract(const Duration(days: 10));
      expect(formatDateRelative(date), formatDate(date));
    });
  });
}
