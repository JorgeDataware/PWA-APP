import '../models/favorite.dart';
import 'api_client.dart';

class FavoritesService {
  static Future<List<Favorite>> getFavorites() async {
    final data = await ApiClient.get('/api/favorites') as List;
    return data.map((e) => Favorite.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Favorite> addFavorite(int newsId) async {
    final data = await ApiClient.post('/api/favorites', {'newsId': newsId});
    return Favorite.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> removeFavorite(int newsId) async {
    await ApiClient.delete('/api/favorites/$newsId');
  }
}
