import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konush/src/features/listings/domain/listing.dart';
import 'package:konush/src/features/listings/domain/listing_filter.dart';
import 'package:konush/src/features/listings/domain/listings_repository.dart';
import 'package:konush/src/core/network/pagination.dart';

sealed class ListingsState extends Equatable {
  const ListingsState();
  @override
  List<Object?> get props => [];
}

class ListingsLoading extends ListingsState {
  const ListingsLoading();
}

class ListingsLoaded extends ListingsState {
  const ListingsLoaded(
    this.items,
    this.meta, {
    this.loadingMore = false,
    this.moreError,
  });
  final List<Listing> items;
  final PaginationMeta meta;
  final bool loadingMore;
  final String? moreError;
  @override
  List<Object?> get props => [items, meta, loadingMore, moreError];
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
  int _request = 0;
  ListingFilter _filter = const ListingFilter();

  Future<void> load([ListingFilter filter = const ListingFilter()]) async {
    if (isClosed) return;
    _filter = filter;
    final request = ++_request;
    emit(const ListingsLoading());
    try {
      final result = await _repository.getListings(filter);
      if (isClosed || request != _request) return;
      emit(ListingsLoaded(result.items, result.meta));
    } catch (error) {
      if (isClosed || request != _request) return;
      emit(ListingsFailure(error.toString()));
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (isClosed ||
        current is! ListingsLoaded ||
        current.loadingMore ||
        !current.meta.hasNext) {
      return;
    }
    final request = _request;
    emit(ListingsLoaded(current.items, current.meta, loadingMore: true));
    try {
      final result = await _repository.getListings(
        _filter.atPage(current.meta.page + 1),
      );
      if (isClosed || request != _request) return;
      final items = {for (final item in current.items) item.id: item};
      for (final item in result.items) {
        items[item.id] = item;
      }
      emit(ListingsLoaded(items.values.toList(), result.meta));
    } catch (_) {
      if (!isClosed && request == _request) {
        emit(
          ListingsLoaded(
            current.items,
            current.meta,
            moreError: 'Не удалось загрузить следующую страницу',
          ),
        );
      }
    }
  }
}
