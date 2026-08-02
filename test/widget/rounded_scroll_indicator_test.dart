import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pwa_app/widgets/rounded_scroll_indicator.dart';

void main() {
  group('RoundedScrollIndicator', () {
    testWidgets('renders nothing before the scroll view has laid out clients', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: RoundedScrollIndicator(controller: controller))),
      );

      expect(find.byType(SizedBox), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('paints once attached to a scrollable with overflow content', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ListView.builder(
                  controller: controller,
                  itemCount: 50,
                  itemBuilder: (_, i) => SizedBox(height: 40, child: Text('Item $i')),
                ),
                RoundedScrollIndicator(controller: controller),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);

      // Scroll and make sure the indicator keeps up without throwing.
      controller.jumpTo(200);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
