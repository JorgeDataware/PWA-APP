import '../models/news.dart';
import 'api_client.dart';

class NewsService {
  static Future<List<News>> getWebNews() async {
    final data = await ApiClient.get('/api/web/news') as List;
    return data.map((e) => News.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<News> getWebNewsById(int id) async {
    final data = await ApiClient.get('/api/web/news/$id');
    return News.fromJson(data as Map<String, dynamic>);
  }

  static Future<News> createNews({
    required String title,
    required String content,
    String? imageUrl,
  }) async {
    final body = <String, dynamic>{'title': title, 'content': content};
    if (imageUrl != null && imageUrl.isNotEmpty) body['imageUrl'] = imageUrl;
    final data = await ApiClient.post('/api/web/news', body);
    return News.fromJson(data as Map<String, dynamic>);
  }

  static Future<News> updateNews(
    int id, {
    String? title,
    String? content,
    String? imageUrl,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (content != null) body['content'] = content;
    if (imageUrl != null) body['imageUrl'] = imageUrl;
    final data = await ApiClient.put('/api/web/news/$id', body);
    return News.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> deleteNews(int id) async {
    await ApiClient.delete('/api/web/news/$id');
  }

  static Future<List<News>> getWearableNews() async {
    final data = await ApiClient.get('/api/wearable/news') as List;
    return data.map((e) => News.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<News> getWearableNewsById(int id) async {
    final data = await ApiClient.get('/api/wearable/news/$id');
    return News.fromJson(data as Map<String, dynamic>);
  }
}
