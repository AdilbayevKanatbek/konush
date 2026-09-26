import 'package:konush/src/features/listings/domain/listing.dart';

enum ListingSort { priceAscending, priceDescending, newest, oldest }

class GeoRadius {
  const GeoRadius({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 3,
  });
  final double latitude;
  final double longitude;
  final double radiusKm;
}

class ListingFilter {
  const ListingFilter({
    this.query,
    this.dealType,
    this.propertyType,
    this.cityId,
    this.districtId,
    this.priceMin,
    this.priceMax,
    this.rooms,
    this.roomsMin,
    this.roomsMax,
    this.areaMin,
    this.areaMax,
    this.floorMin,
    this.floorMax,
    this.near,
    this.sort = ListingSort.newest,
    this.page = 1,
    this.perPage = 20,
  });

  final String? query;
  final DealType? dealType;
  final PropertyType? propertyType;
  final String? cityId;
  final String? districtId;
  final int? priceMin;
  final int? priceMax;
  final int? rooms;
  final int? roomsMin;
  final int? roomsMax;
  final double? areaMin;
  final double? areaMax;
  final int? floorMin;
  final int? floorMax;
  final GeoRadius? near;
  final ListingSort sort;
  final int page;
  final int perPage;

  ListingFilter atPage(int value) => ListingFilter(
    query: query,
    dealType: dealType,
    propertyType: propertyType,
    cityId: cityId,
    districtId: districtId,
    priceMin: priceMin,
    priceMax: priceMax,
    rooms: rooms,
    roomsMin: roomsMin,
    roomsMax: roomsMax,
    areaMin: areaMin,
    areaMax: areaMax,
    floorMin: floorMin,
    floorMax: floorMax,
    near: near,
    sort: sort,
    page: value,
    perPage: perPage,
  );
  Map<String, dynamic> toQuery() => {
    if (query?.trim().isNotEmpty == true) 'q': query!.trim(),
    if (dealType != null) 'deal_type': dealType!.wireName,
    if (propertyType != null) 'property_type': propertyType!.wireName,
    if (cityId != null) 'city_id': cityId,
    if (districtId != null) 'district_id': districtId,
    if (priceMin != null) 'price_min': priceMin,
    if (priceMax != null) 'price_max': priceMax,
    if (rooms != null) 'rooms': rooms,
    if (roomsMin != null) 'rooms_min': roomsMin,
    if (roomsMax != null) 'rooms_max': roomsMax,
    if (areaMin != null) 'area_min': areaMin,
    if (areaMax != null) 'area_max': areaMax,
    if (floorMin != null) 'floor_min': floorMin,
    if (floorMax != null) 'floor_max': floorMax,
    if (near != null) ...{
      'lat': near!.latitude,
      'lng': near!.longitude,
      'radius_km': near!.radiusKm,
    },
    'sort': switch (sort) {
      ListingSort.priceAscending => 'price_asc',
      ListingSort.priceDescending => 'price_desc',
      ListingSort.newest => 'date_desc',
      ListingSort.oldest => 'date_asc',
    },
    'page': page,
    'per_page': perPage.clamp(1, 50),
  };
}
