import 'package:flutter_test/flutter_test.dart';
import 'package:pwa_app/core/dashboard_metrics.dart';
import 'package:pwa_app/models/news.dart';
import 'package:pwa_app/models/user.dart';

News _news(int id, String author, DateTime publishedAt) => News(
      id: id,
      title: 'Noticia $id',
      authorName: author,
      publishedAt: publishedAt,
    );

User _user(int id, {String role = 'User', bool isActive = true}) => User(
      id: id,
      fullName: 'Usuario $id',
      username: 'user$id',
      email: 'user$id@technews.mx',
      role: role,
      isActive: isActive,
    );

void main() {
  // Fixed "now" so the relative windows are deterministic.
  final now = DateTime(2026, 8, 13, 12);

  DashboardMetrics build({List<News>? news, List<User>? users}) =>
      DashboardMetrics(news: news ?? [], users: users ?? [], now: now);

  group('content metrics', () {
    test('counts total news and the last 7 / 30 day windows', () {
      final metrics = build(news: [
        _news(1, 'Ana', now.subtract(const Duration(days: 1))),
        _news(2, 'Ana', now.subtract(const Duration(days: 6))),
        _news(3, 'Beto', now.subtract(const Duration(days: 20))),
        _news(4, 'Beto', now.subtract(const Duration(days: 90))),
      ]);

      expect(metrics.totalNews, 4);
      expect(metrics.newsLast7Days, 2);
      expect(metrics.newsLast30Days, 3);
    });

    test('reports the most recent publication date', () {
      final latest = now.subtract(const Duration(days: 2));
      final metrics = build(news: [
        _news(1, 'Ana', now.subtract(const Duration(days: 30))),
        _news(2, 'Ana', latest),
      ]);

      expect(metrics.lastPublishedAt, latest);
    });

    test('lastPublishedAt is null with no news', () {
      expect(build().lastPublishedAt, isNull);
    });

    test('counts distinct authors', () {
      final metrics = build(news: [
        _news(1, 'Ana', now),
        _news(2, 'Ana', now),
        _news(3, 'Beto', now),
      ]);

      expect(metrics.distinctAuthors, 2);
    });
  });

  group('user metrics', () {
    test('splits active, inactive and admin users', () {
      final metrics = build(users: [
        _user(1, role: 'Admin'),
        _user(2),
        _user(3, isActive: false),
        _user(4, role: 'Guest', isActive: false),
      ]);

      expect(metrics.totalUsers, 4);
      expect(metrics.activeUsers, 2);
      expect(metrics.inactiveUsers, 2);
      expect(metrics.adminUsers, 1);
      expect(metrics.usersWithRole('Guest'), 1);
      // Role counts are independent of the active flag: users 2 and 3.
      expect(metrics.usersWithRole('User'), 2);
    });

    test('handles an empty user base', () {
      final metrics = build();
      expect(metrics.totalUsers, 0);
      expect(metrics.inactiveUsers, 0);
    });
  });

  group('publicationsByMonth', () {
    test('returns one bucket per month, oldest first, zeros included', () {
      final metrics = build(news: [
        _news(1, 'Ana', DateTime(2026, 8, 2)),
        _news(2, 'Ana', DateTime(2026, 8, 9)),
        _news(3, 'Beto', DateTime(2026, 6, 15)),
      ]);

      final buckets = metrics.publicationsByMonth();

      expect(buckets.length, 6);
      expect(buckets.first.month, DateTime(2026, 3));
      expect(buckets.last.month, DateTime(2026, 8));
      expect(buckets.last.count, 2);
      expect(buckets[buckets.length - 3].count, 1); // junio
      expect(buckets[buckets.length - 2].count, 0); // julio, sin publicaciones
    });

    test('ignores articles older than the window', () {
      final metrics = build(news: [_news(1, 'Ana', DateTime(2024, 1, 5))]);
      final buckets = metrics.publicationsByMonth();

      expect(buckets.every((b) => b.count == 0), isTrue);
    });

    test('honours a custom month count', () {
      expect(build().publicationsByMonth(months: 3).length, 3);
    });
  });

  group('topAuthors', () {
    test('ranks by article count, highest first', () {
      final metrics = build(news: [
        _news(1, 'Ana', now),
        _news(2, 'Ana', now),
        _news(3, 'Ana', now),
        _news(4, 'Beto', now),
        _news(5, 'Beto', now),
        _news(6, 'Caro', now),
      ]);

      final top = metrics.topAuthors();

      expect(top.map((a) => a.author).toList(), ['Ana', 'Beto', 'Caro']);
      expect(top.first.count, 3);
    });

    test('breaks ties alphabetically so the order is stable', () {
      final metrics = build(news: [
        _news(1, 'Zoe', now),
        _news(2, 'Ana', now),
      ]);

      expect(metrics.topAuthors().map((a) => a.author).toList(), ['Ana', 'Zoe']);
    });

    test('respects the limit', () {
      final metrics = build(news: [
        for (var i = 1; i <= 8; i++) _news(i, 'Autor $i', now),
      ]);

      expect(metrics.topAuthors(limit: 3).length, 3);
    });
  });

  group('latestNews', () {
    test('sorts newest first and caps the list', () {
      final metrics = build(news: [
        _news(1, 'Ana', now.subtract(const Duration(days: 10))),
        _news(2, 'Ana', now.subtract(const Duration(days: 1))),
        _news(3, 'Beto', now.subtract(const Duration(days: 5))),
      ]);

      final latest = metrics.latestNews(limit: 2);

      expect(latest.map((n) => n.id).toList(), [2, 3]);
    });

    test('does not mutate the source list', () {
      final source = [
        _news(1, 'Ana', now.subtract(const Duration(days: 10))),
        _news(2, 'Ana', now),
      ];
      final metrics = build(news: source);

      metrics.latestNews();

      expect(source.map((n) => n.id).toList(), [1, 2]);
    });
  });
}
