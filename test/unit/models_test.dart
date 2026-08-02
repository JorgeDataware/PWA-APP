import 'package:flutter_test/flutter_test.dart';
import 'package:pwa_app/models/news.dart';
import 'package:pwa_app/models/user.dart';
import 'package:pwa_app/models/favorite.dart';

void main() {
  group('News', () {
    test('fromJson parses all fields from the web API shape', () {
      final json = {
        'id': 42,
        'title': 'IA genera código sin supervisión humana',
        'authorId': 1,
        'authorName': 'Jorge Ramírez',
        'content': 'Contenido completo del artículo.',
        'publishedAt': '2026-06-11T09:30:00Z',
        'imageUrl': 'https://cdn.technews.mx/img/ai-code.jpg',
      };

      final news = News.fromJson(json);

      expect(news.id, 42);
      expect(news.title, 'IA genera código sin supervisión humana');
      expect(news.authorName, 'Jorge Ramírez');
      expect(news.content, 'Contenido completo del artículo.');
      expect(news.imageUrl, 'https://cdn.technews.mx/img/ai-code.jpg');
      expect(news.publishedAt, DateTime.parse('2026-06-11T09:30:00Z'));
    });

    test('fromJson tolerates a null imageUrl and authorId (wearable BFF shape)', () {
      final json = {
        'id': 5,
        'title': 'Título breve',
        'authorId': null,
        'authorName': 'Autora',
        'content': null,
        'publishedAt': '2026-06-11T09:30:00Z',
        'imageUrl': null,
      };

      final news = News.fromJson(json);

      expect(news.authorId, isNull);
      expect(news.imageUrl, isNull);
      expect(news.content, isNull);
    });

    test('contentPreview truncates content longer than 180 chars with an ellipsis', () {
      final longContent = 'A' * 250;
      final news = News(
        id: 1,
        title: 't',
        authorName: 'a',
        content: longContent,
        publishedAt: DateTime(2026, 1, 1),
      );

      expect(news.contentPreview.length, 183); // 180 chars + '...'
      expect(news.contentPreview.endsWith('...'), isTrue);
    });

    test('contentPreview returns the full string when shorter than 180 chars', () {
      final news = News(
        id: 1,
        title: 't',
        authorName: 'a',
        content: 'Corto',
        publishedAt: DateTime(2026, 1, 1),
      );

      expect(news.contentPreview, 'Corto');
    });

    test('contentPreview returns empty string when content is null', () {
      final news = News(
        id: 1,
        title: 't',
        authorName: 'a',
        publishedAt: DateTime(2026, 1, 1),
      );

      expect(news.contentPreview, '');
    });
  });

  group('User', () {
    test('isAdmin is true only when role == "Admin"', () {
      const admin = User(id: 1, fullName: 'A', username: 'a', email: 'a@a.com', role: 'Admin');
      const regular = User(id: 2, fullName: 'B', username: 'b', email: 'b@b.com', role: 'User');

      expect(admin.isAdmin, isTrue);
      expect(regular.isAdmin, isFalse);
    });

    test('fromJson defaults isActive to true and mustChangePassword to false when absent', () {
      final user = User.fromJson({
        'id': 1,
        'fullName': 'A',
        'username': 'a',
        'email': 'a@a.com',
        'role': 'User',
      });

      expect(user.isActive, isTrue);
      expect(user.mustChangePassword, isFalse);
    });
  });

  group('Favorite', () {
    test('fromJson parses newsId and addedAt correctly', () {
      final favorite = Favorite.fromJson({
        'id': 1,
        'newsId': 42,
        'newsTitle': 'Título',
        'newsImageUrl': null,
        'addedAt': '2026-06-16T10:00:00Z',
      });

      expect(favorite.newsId, 42);
      expect(favorite.addedAt, DateTime.parse('2026-06-16T10:00:00Z'));
    });
  });
}
