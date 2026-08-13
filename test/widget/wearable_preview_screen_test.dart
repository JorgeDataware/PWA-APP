import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pwa_app/core/theme.dart';
import 'package:pwa_app/screens/web/wearable_preview_screen.dart';

void main() {
  group('WearablePreviewScreen', () {
    testWidgets('renders the watch frame and its heading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.dark, home: const WearablePreviewScreen()),
      );
      await tester.pump();

      expect(find.text('Vista de smartwatch'), findsOneWidget);
      expect(find.text('TechNews en tu smartwatch'), findsOneWidget);
      // The wearable UI is hosted in a nested navigator so taps inside the
      // watch don't navigate the host page.
      expect(find.byType(Navigator), findsWidgets);
    });

    testWidgets('the watch screen is at or below the wearable breakpoint',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.dark, home: const WearablePreviewScreen()),
      );
      await tester.pump();

      final clip = tester.widget<SizedBox>(
        find.descendant(of: find.byType(ClipOval), matching: find.byType(SizedBox)).first,
      );
      expect(clip.width, lessThanOrEqualTo(320));
      expect(clip.height, lessThanOrEqualTo(320));
    });
  });

  group('WearablePreviewScope', () {
    testWidgets('is inactive outside the preview', (tester) async {
      late bool active;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            active = WearablePreviewScope.isActive(context);
            return const SizedBox();
          }),
        ),
      );
      expect(active, isFalse);
    });

    testWidgets('is active inside the preview scope', (tester) async {
      late bool active;
      await tester.pumpWidget(
        MaterialApp(
          home: WearablePreviewScope(
            child: Builder(builder: (context) {
              active = WearablePreviewScope.isActive(context);
              return const SizedBox();
            }),
          ),
        ),
      );
      expect(active, isTrue);
    });
  });
}
