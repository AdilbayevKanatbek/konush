import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konush/src/features/listings/domain/listing.dart';
import 'package:konush/src/features/listings/domain/listings_repository.dart';

sealed class MyListingsState extends Equatable {
  const MyListingsState();
  @override
  List<Object?> get props => [];
}

class MyListingsLoading extends MyListingsState {
  const MyListingsLoading();
}

class MyListingsLoaded extends MyListingsState {
  const MyListingsLoaded(
    this.items,
    this.total, {
    this.deletingId,
    this.message,
  });
  final List<Listing> items;
  final int total;
  final String? deletingId, message;
  @override
  List<Object?> get props => [items, total, deletingId, message];
}

class MyListingsFailure extends MyListingsState {
  const MyListingsFailure(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class MyListingsCubit extends Cubit<MyListingsState> {
  MyListingsCubit(this._repository) : super(const MyListingsLoading());
  final ListingsRepository _repository;

  int _request = 0;
  Future<void> load() async {
    if (isClosed ||
        state is MyListingsLoaded &&
            (state as MyListingsLoaded).deletingId != null) {
      return;
    }
    final request = ++_request;
    final previous = state;
    if (previous is! MyListingsLoaded) emit(const MyListingsLoading());
    try {
      final items = <Listing>[];
      var page = 1;
      while (true) {
        final result = await _repository.getMyListings(page: page, perPage: 50);
        if (isClosed || request != _request) return;
        items.addAll(result.items);
        if (!result.meta.hasNext) {
          emit(MyListingsLoaded(items, result.meta.total));
          break;
        }
        page++;
      }
    } catch (error) {
      if (isClosed || request != _request) return;
      emit(
        previous is MyListingsLoaded
            ? MyListingsLoaded(
                previous.items,
                previous.total,
                message: error.toString(),
              )
            : MyListingsFailure(error.toString()),
      );
    }
  }

  Future<bool> delete(String id) async {
    final current = state;
    if (current is! MyListingsLoaded || current.deletingId != null) {
      return false;
    }
    _request++;
    emit(MyListingsLoaded(current.items, current.total, deletingId: id));
    try {
      await _repository.deleteListing(id);
      final items = current.items.where((item) => item.id != id).toList();
      if (!isClosed) emit(MyListingsLoaded(items, current.total - 1));
      return true;
    } catch (error) {
      if (!isClosed) {
        emit(
          MyListingsLoaded(
            current.items,
            current.total,
            message: error.toString(),
          ),
        );
      }
      return false;
    }
  }
}
