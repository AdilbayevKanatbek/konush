import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:konush/src/core/error/app_exception.dart';
import 'package:konush/src/features/auth/domain/auth_repository.dart';
import 'package:konush/src/features/listings/domain/listing.dart';
import 'package:konush/src/features/listings/domain/listings_repository.dart';

class FavoritesState extends Equatable {
  const FavoritesState({
    this.ids = const {},
    this.items = const [],
    this.pending = const {},
    this.unavailableIds = const {},
    this.loading = false,
    this.message,
  });
  final Set<String> ids, pending;
  final Set<String> unavailableIds;
  final List<Listing> items;
  final bool loading;
  final String? message;
  FavoritesState copyWith({
    Set<String>? ids,
    Set<String>? pending,
    Set<String>? unavailableIds,
    List<Listing>? items,
    bool? loading,
    String? message,
    bool clearMessage = false,
  }) => FavoritesState(
    ids: ids ?? this.ids,
    items: items ?? this.items,
    pending: pending ?? this.pending,
    unavailableIds: unavailableIds ?? this.unavailableIds,
    loading: loading ?? this.loading,
    message: clearMessage ? null : message ?? this.message,
  );
  @override
  List<Object?> get props => [
    ids,
    items,
    pending,
    unavailableIds,
    loading,
    message,
  ];
}

class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit(this._listings, this._auth, this._storage)
    : super(const FavoritesState());
  final ListingsRepository _listings;
  final AuthRepository _auth;
  final FlutterSecureStorage _storage;
  String? _userId;
  bool _ready = false;
  Future<void>? _loadingUser, _restoring;
  int _scope = 0, _revision = 0;
  final _busy = <String>{};
  Future<void> _writes = Future.value();
  String get _key => _userId == null
      ? 'favorite_listing_ids'
      : 'favorite_listing_ids_$_userId';

  Future<void> restore() async {
    final scope = _scope;
    try {
      final id = await _auth.hasSession()
          ? (await _auth.getProfile()).id
          : null;
      if (isClosed || scope != _scope) return;
      await setUser(id);
    } catch (_) {
      if (!isClosed && scope == _scope) {
        emit(state.copyWith(message: 'Не удалось загрузить избранное'));
      }
    }
  }

  Future<void> setUser(String? id, {bool mergeGuest = false}) {
    if (_userId == id && (_ready || _loadingUser != null)) {
      return _loadingUser ?? Future.value();
    }
    final operation = _setUser(id, mergeGuest: mergeGuest);
    _loadingUser = operation;
    return operation;
  }

  Future<void> _setUser(String? id, {bool mergeGuest = false}) async {
    final guest = mergeGuest && _userId == null ? {...state.ids} : <String>{};
    final scope = ++_scope;
    _revision++;
    _userId = id;
    _ready = false;
    _busy.clear();
    emit(const FavoritesState());
    String? raw;
    try {
      raw = await _storage.read(key: _key);
    } catch (_) {
      if (!isClosed && scope == _scope) {
        _ready = false;
        _loadingUser = null;
        emit(state.copyWith(message: 'Не удалось загрузить избранное'));
      }
      return;
    }
    if (isClosed || scope != _scope) return;
    Set<String> ids = {};
    if (raw != null) {
      try {
        ids = (jsonDecode(raw) as List<dynamic>).cast<String>().toSet();
      } catch (_) {}
    }
    _ready = true;
    _loadingUser = null;
    emit(FavoritesState(ids: ids));
    if (id != null && guest.isNotEmpty) {
      for (final value in guest) {
        if (isClosed || scope != _scope) return;
        try {
          await _listings.addFavorite(value);
        } catch (_) {}
      }
    }
  }

  Future<void> _prepare() async {
    if (_loadingUser != null) await _loadingUser;
    if (!_ready) {
      await (_restoring ??= restore().whenComplete(() {
        _restoring = null;
      }));
    }
  }

  bool contains(String id) => state.ids.contains(id);

  Future<void> toggle(String id) async {
    await _prepare();
    if (!_busy.add(id)) return;
    if (isClosed || !_ready) {
      _busy.remove(id);
      return;
    }
    final scope = _scope;
    _busy.add(id);
    _revision++;
    final wasFavorite = state.ids.contains(id);
    final next = {...state.ids};
    wasFavorite ? next.remove(id) : next.add(id);
    emit(
      state.copyWith(
        ids: next,
        pending: {...state.pending, id},
        loading: false,
        clearMessage: true,
      ),
    );
    try {
      await _save(next);
      if (isClosed || scope != _scope) return;
      if (_userId != null) {
        wasFavorite
            ? await _listings.removeFavorite(id)
            : await _listings.addFavorite(id);
      }
    } catch (_) {
      if (isClosed || scope != _scope) return;
      final rollback = {...state.ids};
      wasFavorite ? rollback.add(id) : rollback.remove(id);
      emit(
        state.copyWith(ids: rollback, message: 'Не удалось изменить избранное'),
      );
      try {
        await _save(rollback);
      } catch (_) {}
    } finally {
      if (scope == _scope) _busy.remove(id);
      if (!isClosed && scope == _scope) {
        emit(state.copyWith(pending: {...state.pending}..remove(id)));
      }
    }
  }

  Future<void> syncWithServer() async {
    await load();
  }

  Future<void> load() async {
    await _prepare();
    if (isClosed || !_ready) return;
    final revision = ++_revision, scope = _scope;
    emit(state.copyWith(loading: true, clearMessage: true));
    try {
      final items = <Listing>[];
      final ids = <String>{};
      final unavailable = <String>{};
      bool failed = false;
      if (_userId != null) {
        var page = 1;
        while (true) {
          final result = await _listings.getFavorites(page: page, perPage: 50);
          items.addAll(result.items);
          ids.addAll(result.items.map((item) => item.id));
          if (!result.meta.hasNext || result.items.isEmpty) break;
          page++;
        }
      } else {
        ids.addAll(state.ids);
        for (final id in {...ids}) {
          try {
            items.add(await _listings.getById(id));
          } catch (error) {
            if (error is AppException &&
                (error.statusCode == 404 || error.code == 'NOT_FOUND')) {
              unavailable.add(id);
              items.addAll(state.items.where((item) => item.id == id));
            } else {
              failed = true;
              items.addAll(state.items.where((item) => item.id == id));
            }
          }
        }
      }
      if (isClosed || revision != _revision || scope != _scope) return;
      emit(
        FavoritesState(
          ids: ids,
          items: items,
          unavailableIds: unavailable,
          message: failed
              ? 'Не удалось обновить избранное. Попробуйте ещё раз.'
              : null,
        ),
      );
      await _save(ids);
    } catch (_) {
      if (!isClosed && revision == _revision && scope == _scope) {
        emit(
          state.copyWith(
            loading: false,
            message: 'Не удалось загрузить избранное',
          ),
        );
      }
    }
  }

  Future<void> _save(Set<String> ids) {
    final key = _key, value = jsonEncode(ids.toList());
    return _writes = _writes
        .catchError((_) {})
        .then((_) => _storage.write(key: key, value: value));
  }
}
