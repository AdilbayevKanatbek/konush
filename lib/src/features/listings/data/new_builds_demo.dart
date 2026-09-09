import 'package:konush/src/features/listings/domain/listing.dart';

const _bishkek = '00000000-0000-0000-0000-000000000001';
final _date = DateTime.utc(2026, 8, 31);

final newBuildsDemo = <Listing>[
  _newBuild(
    id: 'new-build-ala-too-residence',
    title: 'Ала-Тоо Резиденс',
    description:
        '12-этажный комплекс бизнес-класса: квартиры от 42 до 128 м², '
        'двор без машин и рассрочка от застройщика.',
    pricePerSquareMeter: 1050,
    address: 'Магистраль, Бишкек',
    districtId: '00000000-0000-0000-0000-0000000000d7',
    latitude: 42.850,
    longitude: 74.530,
    completionYear: 2027,
    agency: 'Авангард Стиль',
  ),
  _newBuild(
    id: 'new-build-konush-city',
    title: 'Конуш Сити',
    description:
        'Квартал комфорт-класса из пяти башен: собственный парк, школа '
        'и торговая галерея.',
    pricePerSquareMeter: 980,
    address: 'Джал, Бишкек',
    districtId: '00000000-0000-0000-0000-0000000000d1',
    latitude: 42.834,
    longitude: 74.550,
    completionYear: 2028,
    agency: 'Имарат Строй',
  ),
  _newBuild(
    id: 'new-build-tumar-towers',
    title: 'Тумар Тауэрс',
    description:
        'Премиальные башни в центре: панорамное остекление, бассейн на крыше '
        'и коворкинг.',
    pricePerSquareMeter: 1340,
    address: 'Центр города, Бишкек',
    districtId: '00000000-0000-0000-0000-0000000000d6',
    latitude: 42.865,
    longitude: 74.605,
    completionYear: 2027,
    agency: 'Премиум КГ',
  ),
];

Listing _newBuild({
  required String id,
  required String title,
  required String description,
  required int pricePerSquareMeter,
  required String address,
  required String districtId,
  required double latitude,
  required double longitude,
  required int completionYear,
  required String agency,
}) => Listing(
  id: id,
  userId: 'new-build-demo',
  title: title,
  description: description,
  dealType: DealType.sale,
  propertyType: PropertyType.apartment,
  status: ListingStatus.active,
  price: pricePerSquareMeter * 87,
  priceUsd: pricePerSquareMeter,
  isNegotiable: false,
  area: 0,
  year: completionYear,
  cityId: _bishkek,
  districtId: districtId,
  address: address,
  latitude: latitude,
  longitude: longitude,
  photos: const [],
  isVip: false,
  isTop: false,
  seller: 'agency',
  agentName: agency,
  agencyName: agency,
  viewsCount: 0,
  contactsCount: 0,
  createdAt: _date,
  updatedAt: _date,
);
