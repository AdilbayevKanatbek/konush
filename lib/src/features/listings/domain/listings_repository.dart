import 'package:konush/src/core/network/pagination.dart';
import 'package:konush/src/features/listings/domain/listing.dart';
import 'package:konush/src/features/listings/domain/listing_filter.dart';

abstract interface class ListingsRepository {
  Future<PaginatedResult<Listing>> getListings(ListingFilter filter);
  Future<Listing> getById(String id);
  Future<PaginatedResult<Listing>> getFavorites({
    int page = 1,
    int perPage = 50,
  });
  Future<void> addFavorite(String id);
  Future<void> removeFavorite(String id);
  Future<void> recordContact(String id, {String type = 'phone_view'});
  Future<PaginatedResult<Listing>> getMyListings({
    int page = 1,
    int perPage = 20,
  });
  Future<void> deleteListing(String id);
}
