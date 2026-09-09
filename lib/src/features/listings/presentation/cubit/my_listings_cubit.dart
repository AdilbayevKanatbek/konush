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
  const MyListingsLoaded(this.items, this.total, {this.deletingId});
  final List<Listing> items;
  final int total;
  final String? deletingId;
  @override
  List<Object?> get props => [items, total, deletingId];
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

  Future<void> load() async {
    emit(const MyListingsLoading());
    try {
      final result = await _repository.getMyListings(perPage: 50);
      emit(MyListingsLoaded(result.items, result.meta.total));
    } catch (error) {
      emit(MyListingsFailure(error.toString()));
    }
  }

  Future<bool> delete(String id) async {
    final current = state;
    if (current is! MyListingsLoaded) return false;
    emit(MyListingsLoaded(current.items, current.total, deletingId: id));
    try {
      await _repository.deleteListing(id);
      final items = current.items.where((item) => item.id != id).toList();
      emit(MyListingsLoaded(items, current.total - 1));
      return true;
    } catch (error) {
      emit(MyListingsFailure(error.toString()));
      return false;
    }
  }
}
