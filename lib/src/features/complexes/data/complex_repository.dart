import 'package:konush/src/core/network/api_client.dart';
import 'package:konush/src/core/network/pagination.dart';

typedef Json = Map<String, dynamic>;
List<Json> records(Object? value) =>
    (value is List ? value : const []).whereType<Json>().toList();
int? integer(Object? value) => value is num ? value.toInt() : null;
double? decimal(Object? value) => value is num ? value.toDouble() : null;
DateTime? date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
List<String> photoUrls(Object? value) {
  final photos = records(value)
    ..sort(
      (a, b) => (integer(a['order']) ?? 0).compareTo(integer(b['order']) ?? 0),
    );
  return photos.map((p) => p['url']).whereType<String>().toList();
}

class ConstructionRecord {
  ConstructionRecord(this.json);
  final Json json;
  String text(String key) => json[key] is String ? json[key] as String : '';
  int? intValue(String key) => integer(json[key]);
  double? amount(String key) => decimal(json[key]);
  String get id => text('id');
}

class ResidentialComplex extends ConstructionRecord {
  ResidentialComplex.fromJson(super.json);
  String get name => text('name');
  String get address => text('address');
  String get description => text('description');
  String get company => text('company_name');
  String get companyId => text('company_id');
  String get companyLogo => text('company_logo_url');
  String get stage => text('construction_stage');
  bool get completed => stage == 'completed';
  int? get readiness => intValue('readiness_percent');
  int? get handoverYear => intValue('handover_year');
  int? get handoverQuarter => intValue('handover_quarter');
  int? get priceFrom => intValue('price_from');
  int? get parkingPriceFrom => intValue('parking_price_from');
  int? get displayPrice => priceFrom ?? parkingPriceFrom;
  bool get parkingOnly => priceFrom == null && parkingPriceFrom != null;
  int get available => intValue('units_available') ?? 0;
  int get total => intValue('units_total') ?? 0;
  double? get latitude => amount('latitude');
  double? get longitude => amount('longitude');
  DateTime? get catalogDate =>
      date(json['catalog_updated_at']) ?? date(json['created_at']);
  DateTime? get progressDate => date(json['progress_updated_at']);
  List<String> get photos => photoUrls(json['photos']);
  List<Json> get summary => records(json['unit_summary']);
  List<Json> get documents => records(json['documents']);
  List<Json> get banks => records(json['banks']);
  List<MortgageProgram> get mortgages => records(
    json['mortgage_programs'],
  ).where((p) => p['is_active'] != false).map(MortgageProgram.new).toList();
  List<InstallmentPlan> get installments => records(json['installment_plans'])
      .where(
        (p) =>
            p['is_active'] != false &&
            (p['status'] == null || p['status'] == 'active'),
      )
      .map(InstallmentPlan.new)
      .toList();
}

class ComplexUnit extends ConstructionRecord {
  ComplexUnit.fromJson(super.json);
  String get complexId => text('complex_id');
  String get number => text('number');
  String get building => text('building');
  String get type => text('unit_type');
  String get saleStatus => text('sale_status');
  double get area => amount('area') ?? 0;
  int get price => integer(json['price']) ?? 0;
  int? get pricePerM2 => integer(json['price_per_m2']);
  int? get rooms => integer(json['rooms']);
  int? get floor => integer(json['floor']);
  String? get layout => json['layout_url'] as String?;
  List<String> get photos => photoUrls(json['photos']);
}

class ConstructionCompany extends ConstructionRecord {
  ConstructionCompany(super.json);
  String get name => text('name');
  String get ownerId => text('owner_id');
  String get phone => text('phone');
  String get whatsapp => text('whatsapp').isEmpty ? phone : text('whatsapp');
}

class MortgageProgram extends ConstructionRecord {
  MortgageProgram(super.json);
  String get name => text('name');
  Json get bank => json['bank'] is Json ? json['bank'] as Json : const {};
  String get bankName => bank['name'] as String? ?? '';
  double get rate => amount('rate_from') ?? 0;
  int get years => intValue('max_term_years') ?? 1;
  int get minDown => intValue('min_down_pct') ?? 0;
  int? get maxLoan => intValue('max_amount_som');
}

class InstallmentPlan extends ConstructionRecord {
  InstallmentPlan(super.json);
  bool fits(String type) =>
      (json['unit_types'] as List?)?.isNotEmpty != true ||
      (json['unit_types'] as List).contains(type);
  int get months => intValue('term_months') ?? 0;
  int get interval => intValue('payment_interval_months') ?? 0;
  int get down => intValue('down_payment_pct') ?? 0;
  double get markup => amount('markup_pct') ?? 0;
}

class ComplexRepository {
  const ComplexRepository(this.client);
  final ApiClient client;
  Future<PaginatedResult<T>> _list<T>(
    String path,
    Json params,
    T Function(Json) decode,
  ) async {
    final result = await client.get(
      path,
      queryParameters: params,
      decode: (value) => records(value).map(decode).toList(),
    );
    return PaginatedResult(
      items: result.data,
      meta: PaginationMeta.fromJson(result.meta),
    );
  }

  Future<PaginatedResult<ResidentialComplex>> list({
    int page = 1,
    String query = '',
    bool completed = false,
    Json filters = const {},
    int perPage = 20,
  }) => _list('/residential-complexes', {
    ...filters,
    'page': page,
    'per_page': perPage.clamp(1, 50),
    if (query.isNotEmpty) 'q': query,
    if (completed) 'handover_completed': true,
  }, ResidentialComplex.fromJson);
  Future<ResidentialComplex> get(String id) async => (await client.get(
    '/residential-complexes/$id',
    decode: (json) => ResidentialComplex.fromJson(json! as Json),
  )).data;
  Future<PaginatedResult<ComplexUnit>> units(
    String id, {
    int page = 1,
    Json filters = const {},
  }) => _list('/units', {
    ...filters,
    'complex_id': id,
    'page': page,
    'per_page': 20,
  }, ComplexUnit.fromJson);
  Future<ComplexUnit> unit(String id) async => (await client.get(
    '/units/$id',
    decode: (json) => ComplexUnit.fromJson(json! as Json),
  )).data;
  Future<ConstructionCompany> company(String id) async => (await client.get(
    '/companies/$id',
    decode: (json) => ConstructionCompany(json! as Json),
  )).data;
  Future<List<MortgageProgram>> programs() async => (await client.get(
    '/mortgage/programs',
    decode: (json) => records(json).map(MortgageProgram.new).toList(),
  )).data;
  Future<double?> exchangeRate() async {
    try {
      final rate = (await client.get(
        '/exchange-rates/latest',
        queryParameters: {'currency': 'USD'},
        decode: (json) => decimal((json as Json)['rate']),
      )).data;
      return rate != null && rate.isFinite && rate > 0 ? rate : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> contact(String type, String id, String kind) async {
    await client.post(
      '/leads/contact-events',
      data: {'target_type': type, 'target_id': id, 'kind': kind},
      decode: (_) => null,
    );
  }

  Future<void> callback(
    String type,
    String id,
    String time,
    String comment,
  ) async {
    await client.post(
      '/leads/callbacks',
      data: {
        'target_type': type,
        'target_id': id,
        'preferred_time': time,
        'comment': comment,
      },
      decode: (_) => null,
    );
  }

  Future<PaginatedResult<Json>> requests({int page = 1}) =>
      _list('/leads/my', {'page': page, 'per_page': 20}, (json) => json);
}
