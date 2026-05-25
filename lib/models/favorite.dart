class Favorite {
  final int id;
  final int newsId;
  final String newsTitle;
  final String? newsImageUrl;
  final DateTime addedAt;

  const Favorite({
    required this.id,
    required this.newsId,
    required this.newsTitle,
    this.newsImageUrl,
    required this.addedAt,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) => Favorite(
        id: json['id'] as int,
        newsId: json['newsId'] as int,
        newsTitle: json['newsTitle'] as String,
        newsImageUrl: json['newsImageUrl'] as String?,
        addedAt: DateTime.parse(json['addedAt'] as String),
      );
}
