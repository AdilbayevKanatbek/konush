import 'package:equatable/equatable.dart';

class PaginationMeta extends Equatable {
  const PaginationMeta({
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
    this.radiusKm,
  });

  final int page;
  final int perPage;
  final int total;
  final int totalPages;
  final double? radiusKm;

  bool get hasNext => page < totalPages;

  factory PaginationMeta.fromJson(Map<String, dynamic>? json) {
    final value = json ?? const <String, dynamic>{};
    return PaginationMeta(
      page: value['page'] as int? ?? 1,
      perPage: value['per_page'] as int? ?? 20,
      total: value['total'] as int? ?? 0,
      totalPages: value['total_pages'] as int? ?? 0,
      radiusKm: (value['radius_km'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [page, perPage, total, totalPages, radiusKm];
}

class PaginatedResult<T> extends Equatable {
  const PaginatedResult({required this.items, required this.meta});

  final List<T> items;
  final PaginationMeta meta;

  @override
  List<Object?> get props => [items, meta];
}
