import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konush/src/features/listings/domain/listing.dart';
import 'package:konush/src/features/listings/domain/listing_filter.dart';
import 'package:konush/src/features/listings/domain/listings_repository.dart';
import 'package:konush/src/core/network/pagination.dart';
import 'package:konush/src/features/listings/data/new_builds_demo.dart';

sealed class ListingsState extends Equatable {
  const ListingsState();
  @override
  List<Object?> get props => [];
}

class ListingsLoading extends ListingsState {
  const ListingsLoading();
}

class ListingsLoaded extends ListingsState {
  const ListingsLoaded(this.items, this.meta);
  final List<Listing> items;
  final PaginationMeta meta;
  @override
  List<Object?> get props => [items, meta];
}

class ListingsFailure extends ListingsState {
  const ListingsFailure(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class ListingsCubit extends Cubit<ListingsState> {
  ListingsCubit(this._repository) : super(const ListingsLoading());
  final ListingsRepository _repository;

  Future<void> load([ListingFilter filter = const ListingFilter()]) async {
    emit(const ListingsLoading());
    try {
      final result = await _repository.getListings(filter);
      emit(ListingsLoaded(result.items, result.meta));
    } catch (error) {
      emit(ListingsFailure(error.toString()));
    }
  }

  void loadNewBuilds([ListingFilter filter = const ListingFilter()]) {
    emit(const ListingsLoading());
    final items = newBuildsDemo.where((item) {
      if (filter.rooms != null && item.rooms != filter.rooms) return false;
      if (filter.districtId != null && item.districtId != filter.districtId) {
        return false;
      }
      if (filter.priceMin != null && (item.priceUsd ?? 0) < filter.priceMin!) {
        return false;
      }
      if (filter.priceMax != null && (item.priceUsd ?? 0) > filter.priceMax!) {
        return false;
      }
      return true;
    }).toList();
    emit(
      ListingsLoaded(
        items,
        PaginationMeta(
          page: 1,
          perPage: items.length,
          total: items.length,
          totalPages: items.isEmpty ? 0 : 1,
        ),
      ),
    );
  }
}
