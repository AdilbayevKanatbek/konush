import 'package:konush/src/core/network/pagination.dart';
import 'package:konush/src/features/listings/data/listings_remote_data_source.dart';
import 'package:konush/src/features/listings/domain/listing.dart';
import 'package:konush/src/features/listings/domain/listing_filter.dart';
import 'package:konush/src/features/listings/domain/listings_repository.dart';

class ListingsRepositoryImpl implements ListingsRepository {
  const ListingsRepositoryImpl(this._remote);
  final ListingsRemoteDataSource _remote;

  @override
  Future<PaginatedResult<Listing>> getListings(ListingFilter filter) =>
      _remote.getListings(filter);

  @override
  Future<Listing> getById(String id) => _remote.getById(id);

  @override
  Future<PaginatedResult<Listing>> getFavorites({
    int page = 1,
    int perPage = 50,
  }) => _remote.getFavorites(page: page, perPage: perPage);

  @override
  Future<void> addFavorite(String id) => _remote.addFavorite(id);

  @override
  Future<void> removeFavorite(String id) => _remote.removeFavorite(id);

  @override
  Future<void> recordContact(String id, {String type = 'phone_view'}) =>
      _remote.recordContact(id, type: type);

  @override
  Future<PaginatedResult<Listing>> getMyListings({
    int page = 1,
    int perPage = 20,
  }) => _remote.getMyListings(page: page, perPage: perPage);

  @override
  Future<void> deleteListing(String id) => _remote.deleteListing(id);
}
