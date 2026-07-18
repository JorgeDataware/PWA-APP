import '../core/constants.dart';
import '../core/mock_data.dart';
import '../models/news.dart';
import 'api_client.dart';

class NewsService {
  static Future<List<News>> getWebNews() async {
    if (AppConstants.useMockData) return MockData.news();
    final data = await ApiClient.get('/api/web/news') as List;
    return data.map((e) => News.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<News> getWebNewsById(int id) async {
    if (AppConstants.useMockData) return MockData.newsById(id);
    final data = await ApiClient.get('/api/web/news/$id');
    return News.fromJson(data as Map<String, dynamic>);
  }

  static Future<News> createNews({
    required String title,
    required String content,
    String? imageUrl,
  }) async {
    if (AppConstants.useMockData) {
      return MockData.createNews(
        title: title,
        content: content,
        imageUrl: imageUrl != null && imageUrl.isNotEmpty ? imageUrl : null,
      );
    }
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
    if (AppConstants.useMockData) {
      return MockData.updateNews(
        id,
        title: title,
        content: content,
        imageUrl: imageUrl,
      );
    }
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (content != null) body['content'] = content;
    if (imageUrl != null) body['imageUrl'] = imageUrl;
    final data = await ApiClient.put('/api/web/news/$id', body);
    return News.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> deleteNews(int id) async {
    if (AppConstants.useMockData) return MockData.deleteNews(id);
    await ApiClient.delete('/api/web/news/$id');
  }

  static Future<List<News>> getWearableNews() async {
    if (AppConstants.useMockData) return MockData.news();
    final data = await ApiClient.get('/api/wearable/news') as List;
    return data.map((e) => News.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<News> getWearableNewsById(int id) async {
    if (AppConstants.useMockData) return MockData.newsById(id);
    final data = await ApiClient.get('/api/wearable/news/$id');
    return News.fromJson(data as Map<String, dynamic>);
  }
}
