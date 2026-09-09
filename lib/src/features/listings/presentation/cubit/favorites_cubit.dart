import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:konush/src/features/auth/domain/auth_repository.dart';
import 'package:konush/src/features/listings/domain/listing.dart';
import 'package:konush/src/features/listings/domain/listings_repository.dart';

class FavoritesState extends Equatable {
  const FavoritesState({
    this.ids = const {},
    this.items = const [],
    this.loading = false,
    this.message,
  });
  final Set<String> ids;
  final List<Listing> items;
  final bool loading;
  final String? message;

  FavoritesState copyWith({
    Set<String>? ids,
    List<Listing>? items,
    bool? loading,
    String? message,
    bool clearMessage = false,
  }) => FavoritesState(
    ids: ids ?? this.ids,
    items: items ?? this.items,
    loading: loading ?? this.loading,
    message: clearMessage ? null : message ?? this.message,
  );

  @override
  List<Object?> get props => [ids, items, loading, message];
}

class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit(this._listings, this._auth, this._storage)
    : super(const FavoritesState());

  static const _key = 'favorite_listing_ids';
  final ListingsRepository _listings;
  final AuthRepository _auth;
  final FlutterSecureStorage _storage;

  Future<void> restore() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return;
    try {
      final ids = (jsonDecode(raw) as List<dynamic>).cast<String>().toSet();
      emit(state.copyWith(ids: ids));
    } catch (_) {
      await _storage.delete(key: _key);
    }
  }

  bool contains(String id) => state.ids.contains(id);

  Future<void> toggle(String id) async {
    final wasFavorite = state.ids.contains(id);
    final next = {...state.ids};
    wasFavorite ? next.remove(id) : next.add(id);
    emit(state.copyWith(ids: next, clearMessage: true));
    await _save(next);

    if (!await _auth.hasSession()) return;
    try {
      wasFavorite
          ? await _listings.removeFavorite(id)
          : await _listings.addFavorite(id);
    } catch (error) {
      final rollback = {...next};
      wasFavorite ? rollback.add(id) : rollback.remove(id);
      emit(state.copyWith(ids: rollback, message: error.toString()));
      await _save(rollback);
    }
  }

  Future<void> syncWithServer() async {
    if (!await _auth.hasSession()) return;
    final local = {...state.ids};
    for (final id in local) {
      try {
        await _listings.addFavorite(id);
      } catch (_) {}
    }
    await load();
  }

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearMessage: true));
    try {
      List<Listing> items;
      if (await _auth.hasSession()) {
        items = (await _listings.getFavorites()).items;
      } else {
        final values = await Future.wait(
          state.ids.map(
            (id) => _listings
                .getById(id)
                .then<Listing?>((v) => v)
                .catchError((_) => null),
          ),
        );
        items = values.whereType<Listing>().toList();
      }
      final ids = items.map((item) => item.id).toSet();
      emit(FavoritesState(ids: ids, items: items));
      await _save(ids);
    } catch (error) {
      emit(state.copyWith(loading: false, message: error.toString()));
    }
  }

  Future<void> _save(Set<String> ids) =>
      _storage.write(key: _key, value: jsonEncode(ids.toList()));
}
