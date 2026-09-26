import 'package:flutter_test/flutter_test.dart';
import 'package:konush/src/features/listings/domain/listing.dart';
import 'package:konush/src/features/listings/domain/listing_filter.dart';

void main() {
  test('ListingFilter uses exact Swagger query parameter names', () {
    const filter = ListingFilter(
      query: 'Джал',
      dealType: DealType.sale,
      propertyType: PropertyType.apartment,
      rooms: 3,
      priceMax: 9000000,
      near: GeoRadius(latitude: 42.87, longitude: 74.59, radiusKm: 5),
      sort: ListingSort.priceAscending,
      page: 2,
      perPage: 100,
    );

    expect(filter.toQuery(), containsPair('q', 'Джал'));
    expect(filter.toQuery(), containsPair('deal_type', 'sale'));
    expect(filter.toQuery(), containsPair('property_type', 'apartment'));
    expect(filter.toQuery(), containsPair('sort', 'price_asc'));
    expect(filter.toQuery(), containsPair('radius_km', 5));
    expect(filter.toQuery(), containsPair('per_page', 50));
    expect(filter.toQuery(), isNot(contains('sort_by')));
  });
}
