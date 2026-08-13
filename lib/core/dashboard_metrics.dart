import '../models/news.dart';
import '../models/user.dart';

/// A single bar of the "publicaciones por mes" chart.
class MonthlyCount {
  /// First day of the month the bucket covers.
  final DateTime month;
  final int count;

  const MonthlyCount({required this.month, required this.count});
}

/// An entry of the "top autores" ranking.
class AuthorCount {
  final String author;
  final int count;

  const AuthorCount({required this.author, required this.count});
}

/// Aggregates the admin dashboard figures from the data the app already
/// fetches (news + users), so no extra endpoint is needed. Kept free of
/// Flutter imports so the arithmetic can be unit-tested on its own.
class DashboardMetrics {
  final List<News> news;
  final List<User> users;

  /// Reference instant for the relative windows ("last 7 days", "last N
  /// months"). Injectable so tests are deterministic.
  final DateTime now;

  DashboardMetrics({
    required this.news,
    required this.users,
    DateTime? now,
  }) : now = now ?? DateTime.now();

  int get totalNews => news.length;

  int get newsLast7Days {
    final cutoff = now.subtract(const Duration(days: 7));
    return news.where((n) => n.publishedAt.isAfter(cutoff)).length;
  }

  int get newsLast30Days {
    final cutoff = now.subtract(const Duration(days: 30));
    return news.where((n) => n.publishedAt.isAfter(cutoff)).length;
  }

  int get totalUsers => users.length;
  int get activeUsers => users.where((u) => u.isActive).length;
  int get inactiveUsers => totalUsers - activeUsers;
  int get adminUsers => users.where((u) => u.isAdmin).length;

  int usersWithRole(String role) => users.where((u) => u.role == role).length;

  /// Distinct authors that have published at least one article.
  int get distinctAuthors => news.map((n) => n.authorName).toSet().length;

  DateTime? get lastPublishedAt {
    if (news.isEmpty) return null;
    return news
        .map((n) => n.publishedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  /// The [months] most recent months, oldest first, including months with no
  /// articles so the chart keeps an even time axis.
  List<MonthlyCount> publicationsByMonth({int months = 6}) {
    final buckets = <DateTime, int>{};
    for (var i = months - 1; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i);
      buckets[m] = 0;
    }
    final oldest = buckets.keys.first;
    for (final n in news) {
      final local = n.publishedAt.toLocal();
      final m = DateTime(local.year, local.month);
      if (m.isBefore(oldest)) continue;
      if (buckets.containsKey(m)) buckets[m] = buckets[m]! + 1;
    }
    return buckets.entries
        .map((e) => MonthlyCount(month: e.key, count: e.value))
        .toList();
  }

  /// Authors ranked by article count, highest first. Ties are broken
  /// alphabetically so the ranking is stable between reloads.
  List<AuthorCount> topAuthors({int limit = 5}) {
    final counts = <String, int>{};
    for (final n in news) {
      counts[n.authorName] = (counts[n.authorName] ?? 0) + 1;
    }
    final ranked = counts.entries
        .map((e) => AuthorCount(author: e.key, count: e.value))
        .toList()
      ..sort((a, b) {
        final byCount = b.count.compareTo(a.count);
        return byCount != 0 ? byCount : a.author.compareTo(b.author);
      });
    return ranked.take(limit).toList();
  }

  /// Most recent articles, newest first.
  List<News> latestNews({int limit = 5}) {
    final sorted = [...news]
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return sorted.take(limit).toList();
  }
}
