import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konush/src/core/error/app_exception.dart';
import 'package:konush/src/features/auth/domain/auth_repository.dart';
import 'package:konush/src/features/auth/domain/user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, loading, failure }

class AuthState extends Equatable {
  const AuthState(this.status, {this.user, this.message});
  const AuthState.initial() : this(AuthStatus.unknown);

  final AuthStatus status;
  final User? user;
  final String? message;

  @override
  List<Object?> get props => [status, user, message];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthState.initial());
  final AuthRepository _repository;

  Future<void> restoreSession() async {
    final exists = await _repository.hasSession();
    if (!exists) {
      emit(const AuthState(AuthStatus.unauthenticated));
      return;
    }
    try {
      final user = await _repository.getProfile();
      emit(AuthState(AuthStatus.authenticated, user: user));
    } catch (_) {
      await _repository.logout();
      emit(const AuthState(AuthStatus.unauthenticated));
    }
  }

  Future<void> login(String phone, String password) async {
    emit(const AuthState(AuthStatus.loading));
    try {
      final user = await _repository.login(phone: phone, password: password);
      emit(AuthState(AuthStatus.authenticated, user: user));
    } catch (error) {
      emit(
        AuthState(
          AuthStatus.failure,
          message: error is AppException ? error.userMessage : error.toString(),
        ),
      );
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    emit(const AuthState(AuthStatus.unauthenticated));
  }
}
