class News {
  final int id;
  final String title;
  final int? authorId;
  final String authorName;
  final String? content;
  final DateTime publishedAt;
  final String? imageUrl;

  const News({
    required this.id,
    required this.title,
    this.authorId,
    required this.authorName,
    this.content,
    required this.publishedAt,
    this.imageUrl,
  });

  String get contentPreview {
    if (content == null || content!.isEmpty) return '';
    return content!.length > 180 ? '${content!.substring(0, 180)}...' : content!;
  }

  factory News.fromJson(Map<String, dynamic> json) => News(
        id: json['id'] as int,
        title: json['title'] as String,
        authorId: json['authorId'] as int?,
        authorName: json['authorName'] as String,
        content: json['content'] as String?,
        publishedAt: DateTime.parse(json['publishedAt'] as String),
        imageUrl: json['imageUrl'] as String?,
      );

  Map<String, dynamic> toCreateJson() => {
        'title': title,
        if (content != null) 'content': content,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };
}
