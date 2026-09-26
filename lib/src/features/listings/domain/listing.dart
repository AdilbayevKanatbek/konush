import 'package:equatable/equatable.dart';

enum DealType { sale, rent, rentDay }

enum PropertyType { apartment, house, commercial, land, garage }

enum ListingStatus { draft, pending, active, sold, archived, rejected }

extension DealTypeX on DealType {
  String get wireName => switch (this) {
    DealType.sale => 'sale',
    DealType.rent => 'rent',
    DealType.rentDay => 'rent_day',
  };
  bool get isRent => this == DealType.rent || this == DealType.rentDay;
}

extension PropertyTypeX on PropertyType {
  String get wireName => name;
}

class ListingPhoto extends Equatable {
  const ListingPhoto({
    required this.id,
    required this.listingId,
    required this.url,
    required this.order,
    required this.createdAt,
  });

  final String id;
  final String listingId;
  final String url;
  final int order;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, listingId, url, order, createdAt];
}

class Listing extends Equatable {
  const Listing({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.dealType,
    required this.propertyType,
    required this.status,
    required this.price,
    required this.isNegotiable,
    required this.area,
    required this.cityId,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.photos,
    required this.isVip,
    required this.isTop,
    required this.seller,
    required this.agentName,
    required this.viewsCount,
    required this.contactsCount,
    required this.createdAt,
    required this.updatedAt,
    this.agencyId,
    this.priceUsd,
    this.rooms,
    this.floor,
    this.totalFloors,
    this.landArea,
    this.year,
    this.districtId,
    this.videoUrl,
    this.vipUntil,
    this.topUntil,
    this.bumpUntil,
    this.bumpedAt,
    this.agencyName,
    this.rejectReason,
    this.contactPhone,
    this.isPublic,
  });

  final String id;
  final String userId;
  final String? agencyId;
  final String title;
  final String description;
  final DealType dealType;
  final PropertyType propertyType;
  final ListingStatus status;
  final int price;
  final int? priceUsd;
  final bool isNegotiable;
  final int? rooms;
  final int? floor;
  final int? totalFloors;
  final double area;
  final double? landArea;
  final int? year;
  final String cityId;
  final String? districtId;
  final String address;
  final double latitude;
  final double longitude;
  final List<ListingPhoto> photos;
  final String? videoUrl;
  final bool isVip;
  final bool isTop;
  final DateTime? vipUntil;
  final DateTime? topUntil;
  final DateTime? bumpUntil;
  final DateTime? bumpedAt;
  final String seller;
  final String agentName;
  final String? agencyName;
  final int viewsCount;
  final int contactsCount;
  final String? rejectReason;
  final String? contactPhone;

  /// Only supplied by the favorites API. Missing does not mean unavailable.
  final bool? isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get currency => 'KGS';
  bool get canEdit =>
      status == ListingStatus.active ||
      status == ListingStatus.pending ||
      status == ListingStatus.rejected;
  String? get photoUrl => photos.isEmpty ? null : photos.first.url;
  String get city => switch (cityId) {
    '00000000-0000-0000-0000-000000000001' => 'Бишкек',
    '00000000-0000-0000-0000-000000000002' => 'Ош',
    '00000000-0000-0000-0000-000000000003' => 'Джалал-Абад',
    '00000000-0000-0000-0000-000000000004' => 'Каракол',
    '00000000-0000-0000-0000-000000000005' => 'Нарын',
    '00000000-0000-0000-0000-000000000006' => 'Талас',
    '00000000-0000-0000-0000-000000000007' => 'Баткен',
    _ => '',
  };

  @override
  List<Object?> get props => [
    id,
    userId,
    agencyId,
    title,
    description,
    dealType,
    propertyType,
    status,
    price,
    priceUsd,
    isNegotiable,
    rooms,
    floor,
    totalFloors,
    area,
    landArea,
    year,
    cityId,
    districtId,
    address,
    latitude,
    longitude,
    photos,
    videoUrl,
    isVip,
    isTop,
    vipUntil,
    topUntil,
    bumpUntil,
    bumpedAt,
    seller,
    agentName,
    agencyName,
    viewsCount,
    contactsCount,
    rejectReason,
    contactPhone,
    isPublic,
    createdAt,
    updatedAt,
  ];
}
