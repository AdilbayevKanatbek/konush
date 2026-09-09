import 'package:flutter_test/flutter_test.dart';
import 'package:konush/src/core/network/pagination.dart';

void main() {
  test('PaginationMeta decodes list metadata and reports next page', () {
    final meta = PaginationMeta.fromJson({
      'page': 2,
      'per_page': 20,
      'total': 61,
      'total_pages': 4,
      'radius_km': 50,
    });

    expect(meta.hasNext, isTrue);
    expect(meta.total, 61);
    expect(meta.radiusKm, 50);
  });
}
