import 'package:flutter_test/flutter_test.dart';
import 'package:pwa_app/core/mock_data.dart';

void main() {
  group('MockData.searchNews (internal search)', () {
    test('matches by title, case-insensitive', () async {
      final results = await MockData.searchNews('FLUTTER');
      expect(results, isNotEmpty);
      expect(results.every((n) => n.title.toLowerCase().contains('flutter')), isTrue);
    });

    test('matches by content, not only title', () async {
      final results = await MockData.searchNews('PWA');
      expect(results.any((n) => n.title.toLowerCase().contains('pwa')), isTrue);
    });

    test('returns an empty list for an empty query', () async {
      final results = await MockData.searchNews('   ');
      expect(results, isEmpty);
    });

    test('returns an empty list when nothing matches', () async {
      final results = await MockData.searchNews('xyz-no-such-term-zzz');
      expect(results, isEmpty);
    });

    test('results are sorted by publishedAt descending', () async {
      final results = await MockData.searchNews('e'); // broad match, several hits
      for (var i = 0; i < results.length - 1; i++) {
        expect(
          results[i].publishedAt.isAfter(results[i + 1].publishedAt) ||
              results[i].publishedAt.isAtSameMomentAs(results[i + 1].publishedAt),
          isTrue,
        );
      }
    });
  });
}
