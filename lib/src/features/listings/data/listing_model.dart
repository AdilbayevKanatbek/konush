import 'package:konush/src/features/listings/domain/listing.dart';

class ListingPhotoModel extends ListingPhoto {
  const ListingPhotoModel({
    required super.id,
    required super.listingId,
    required super.url,
    required super.order,
    required super.createdAt,
  });

  factory ListingPhotoModel.fromJson(Map<String, dynamic> json) =>
      ListingPhotoModel(
        id: json['id'] as String? ?? '',
        listingId: json['listing_id'] as String? ?? '',
        url: json['url'] as String,
        order: json['order'] as int? ?? 0,
        createdAt: _date(json['created_at']),
      );
}

class ListingModel extends Listing {
  const ListingModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.description,
    required super.dealType,
    required super.propertyType,
    required super.status,
    required super.price,
    required super.isNegotiable,
    required super.area,
    required super.cityId,
    required super.address,
    required super.latitude,
    required super.longitude,
    required super.photos,
    required super.isVip,
    required super.isTop,
    required super.seller,
    required super.agentName,
    required super.viewsCount,
    required super.contactsCount,
    required super.createdAt,
    required super.updatedAt,
    super.agencyId,
    super.priceUsd,
    super.rooms,
    super.floor,
    super.totalFloors,
    super.landArea,
    super.year,
    super.districtId,
    super.videoUrl,
    super.vipUntil,
    super.topUntil,
    super.bumpUntil,
    super.bumpedAt,
    super.agencyName,
    super.rejectReason,
    super.contactPhone,
  });

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    final rawPhotos = json['photos'] as List<dynamic>? ?? const [];
    return ListingModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      agencyId: json['agency_id'] as String?,
      title: json['title'] as String? ?? 'Объявление',
      description: json['description'] as String? ?? '',
      dealType: _dealType(json['deal_type'] as String?),
      propertyType: _propertyType(json['property_type'] as String?),
      status: _status(json['status'] as String?),
      price: (json['price'] as num? ?? 0).toInt(),
      priceUsd: (json['price_usd'] as num?)?.toInt(),
      isNegotiable: json['is_negotiable'] as bool? ?? false,
      rooms: json['rooms'] as int?,
      floor: json['floor'] as int?,
      totalFloors: json['floors'] as int?,
      area: (json['area'] as num? ?? 0).toDouble(),
      landArea: (json['land_area'] as num?)?.toDouble(),
      year: json['year'] as int?,
      cityId: json['city_id'] as String? ?? '',
      districtId: json['district_id'] as String?,
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num? ?? 0).toDouble(),
      longitude: (json['longitude'] as num? ?? 0).toDouble(),
      photos:
          rawPhotos
              .whereType<Map<String, dynamic>>()
              .map(ListingPhotoModel.fromJson)
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order)),
      videoUrl: json['video_url'] as String?,
      isVip: json['is_vip'] as bool? ?? false,
      isTop: json['is_top'] as bool? ?? false,
      vipUntil: _nullableDate(json['vip_until']),
      topUntil: _nullableDate(json['top_until']),
      bumpUntil: _nullableDate(json['bump_until']),
      bumpedAt: _nullableDate(json['bumped_at']),
      seller: json['seller'] as String? ?? 'owner',
      agentName: json['agent_name'] as String? ?? '',
      agencyName: json['agency_name'] as String?,
      viewsCount: json['views_count'] as int? ?? 0,
      contactsCount: json['contacts_count'] as int? ?? 0,
      rejectReason: json['reject_reason'] as String?,
      contactPhone: json['contact_phone'] as String?,
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
    );
  }
}

DateTime _date(Object? value) =>
    _nullableDate(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
DateTime? _nullableDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
DealType _dealType(String? value) => switch (value) {
  'rent' => DealType.rent,
  'rent_day' => DealType.rentDay,
  _ => DealType.sale,
};
PropertyType _propertyType(String? value) => switch (value) {
  'house' => PropertyType.house,
  'commercial' => PropertyType.commercial,
  'land' => PropertyType.land,
  'garage' => PropertyType.garage,
  _ => PropertyType.apartment,
};
ListingStatus _status(String? value) => switch (value) {
  'draft' => ListingStatus.draft,
  'pending' => ListingStatus.pending,
  'sold' => ListingStatus.sold,
  'archived' => ListingStatus.archived,
  'rejected' => ListingStatus.rejected,
  _ => ListingStatus.active,
};
