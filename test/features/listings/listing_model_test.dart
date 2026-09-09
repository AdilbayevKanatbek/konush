import 'package:flutter_test/flutter_test.dart';
import 'package:konush/src/features/listings/data/listing_model.dart';
import 'package:konush/src/features/listings/domain/listing.dart';

void main() {
  test('ListingModel decodes the complete Swagger listing contract', () {
    final listing = ListingModel.fromJson({
      'id': 'listing-id',
      'user_id': 'user-id',
      'title': 'Квартира в центре Бишкека',
      'description': 'Просторная квартира с хорошим ремонтом',
      'deal_type': 'rent_day',
      'property_type': 'apartment',
      'status': 'active',
      'price': 85000,
      'price_usd': 970,
      'is_negotiable': true,
      'rooms': 3,
      'floor': 5,
      'floors': 9,
      'area': 72.5,
      'city_id': '00000000-0000-0000-0000-000000000001',
      'address': 'ул. Киевская, 10',
      'latitude': 42.87,
      'longitude': 74.59,
      'photos': [
        {
          'id': 'photo-id',
          'listing_id': 'listing-id',
          'url': 'http://media.example/photo.webp',
          'order': 0,
          'created_at': '2026-08-21T12:00:00Z',
        },
      ],
      'is_vip': true,
      'is_top': false,
      'seller': 'agency',
      'agent_name': 'Айбек',
      'agency_name': 'Konush Realty',
      'views_count': 15,
      'contacts_count': 2,
      'created_at': '2026-08-21T12:00:00Z',
      'updated_at': '2026-08-21T12:00:00Z',
    });

    expect(listing.dealType, DealType.rentDay);
    expect(listing.propertyType, PropertyType.apartment);
    expect(listing.status, ListingStatus.active);
    expect(listing.area, 72.5);
    expect(listing.city, 'Бишкек');
    expect(listing.photoUrl, 'http://media.example/photo.webp');
    expect(listing.isVip, isTrue);
  });
}
