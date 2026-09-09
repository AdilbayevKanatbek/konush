import 'package:konush/src/core/network/api_client.dart';
import 'package:konush/src/core/network/pagination.dart';
import 'package:konush/src/features/listings/data/listing_model.dart';
import 'package:konush/src/features/listings/domain/listing_filter.dart';

class ListingsRemoteDataSource {
  const ListingsRemoteDataSource(this._client);
  final ApiClient _client;

  Future<PaginatedResult<ListingModel>> getListings(
    ListingFilter filter,
  ) async {
    final response = await _client.get(
      '/listings',
      queryParameters: filter.toQuery(),
      decode: (value) => (value! as List<dynamic>)
          .map((item) => ListingModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
    return PaginatedResult(
      items: response.data,
      meta: PaginationMeta.fromJson(response.meta),
    );
  }

  Future<ListingModel> getById(String id) async {
    final response = await _client.get(
      '/listings/$id',
      decode: (value) => ListingModel.fromJson(value! as Map<String, dynamic>),
    );
    return response.data;
  }

  Future<PaginatedResult<ListingModel>> getFavorites({
    int page = 1,
    int perPage = 50,
  }) async {
    final response = await _client.get(
      '/favorites',
      queryParameters: {'page': page, 'per_page': perPage},
      decode: (value) => (value! as List<dynamic>)
          .map((item) => ListingModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
    return PaginatedResult(
      items: response.data,
      meta: PaginationMeta.fromJson(response.meta),
    );
  }

  Future<void> addFavorite(String id) =>
      _message('POST', '/listings/$id/favorites');
  Future<void> removeFavorite(String id) =>
      _message('DELETE', '/listings/$id/favorites');

  Future<void> recordContact(String id, {String type = 'phone_view'}) async {
    await _client.post<Map<String, dynamic>>(
      '/listings/$id/contact',
      data: {'contact_type': type},
      decode: (value) => value! as Map<String, dynamic>,
    );
  }

  Future<PaginatedResult<ListingModel>> getMyListings({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _client.get(
      '/listings/my',
      queryParameters: {'page': page, 'per_page': perPage},
      decode: (value) => (value! as List<dynamic>)
          .map((item) => ListingModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
    return PaginatedResult(
      items: response.data,
      meta: PaginationMeta.fromJson(response.meta),
    );
  }

  Future<void> deleteListing(String id) => _message('DELETE', '/listings/$id');

  Future<void> _message(String method, String path) async {
    if (method == 'POST') {
      await _client.post<Map<String, dynamic>>(
        path,
        decode: (value) => value! as Map<String, dynamic>,
      );
    } else {
      await _client.delete<Map<String, dynamic>>(
        path,
        decode: (value) => value! as Map<String, dynamic>,
      );
    }
  }
}
