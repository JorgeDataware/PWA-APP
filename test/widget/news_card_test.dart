import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pwa_app/core/theme.dart';
import 'package:pwa_app/models/news.dart';
import 'package:pwa_app/widgets/news_card.dart';

News _news({String? imageUrl}) => News(
      id: 1,
      title: 'Título de prueba',
      authorName: 'Autor de prueba',
      content: 'Contenido de prueba',
      publishedAt: DateTime.now(),
      imageUrl: imageUrl,
    );

Widget _wrap(Widget child) => MaterialApp(theme: AppTheme.dark, home: Scaffold(body: child));

void main() {
  group('NewsCard', () {
    testWidgets('renders title and author', (tester) async {
      await tester.pumpWidget(
        _wrap(NewsCard(news: _news(), onTap: () {})),
      );

      expect(find.text('Título de prueba'), findsOneWidget);
      expect(find.text('Autor de prueba'), findsOneWidget);
    });

    testWidgets('tapping the card triggers onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(NewsCard(news: _news(), onTap: () => tapped = true)),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('shows a filled bookmark when isFavorite is true', (tester) async {
      await tester.pumpWidget(
        _wrap(NewsCard(news: _news(), onTap: () {}, isFavorite: true, onFavoriteToggle: () {})),
      );

      expect(find.byIcon(Icons.bookmark), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border), findsNothing);
    });

    testWidgets('shows the locked bookmark style for guests and still calls the callback', (tester) async {
      var promptedLogin = false;
      await tester.pumpWidget(
        _wrap(NewsCard(
          news: _news(),
          onTap: () {},
          favoriteLocked: true,
          onFavoriteToggle: () => promptedLogin = true,
        )),
      );

      expect(find.byIcon(Icons.bookmark_outline), findsOneWidget);
      await tester.tap(find.byIcon(Icons.bookmark_outline));
      expect(promptedLogin, isTrue);
    });

    testWidgets('hides the bookmark button entirely when onFavoriteToggle is null', (tester) async {
      await tester.pumpWidget(
        _wrap(NewsCard(news: _news(), onTap: () {})),
      );

      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('falls back to a broken-image icon when the image URL fails to load', (tester) async {
      await tester.pumpWidget(
        _wrap(NewsCard(news: _news(imageUrl: 'https://invalid.invalid/x.png'), onTap: () {})),
      );
      await tester.pump();

      // The network image errors synchronously in the test environment
      // (no real HTTP client), so the errorBuilder fallback icon should show.
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    });
  });
}
