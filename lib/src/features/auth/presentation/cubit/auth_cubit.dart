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

  int _request = 0;
  Future<void> restoreSession() async {
    final request = ++_request;
    final previous = state.user;
    try {
      final exists = await _repository.hasSession();
      if (isClosed || request != _request) return;
      if (!exists) {
        emit(const AuthState(AuthStatus.unauthenticated));
        return;
      }
      final user = await _repository.getProfile();
      if (!isClosed && request == _request) {
        emit(AuthState(AuthStatus.authenticated, user: user));
      }
    } catch (error) {
      if (isClosed || request != _request) return;
      final expired =
          error is AppException &&
          (error.statusCode == 401 ||
              error.code == 'UNAUTHORIZED' ||
              error.code == 'USER_BANNED');
      if (expired) {
        await _repository.logout();
        if (!isClosed && request == _request) {
          emit(const AuthState(AuthStatus.unauthenticated));
        }
      } else {
        emit(
          AuthState(
            previous == null ? AuthStatus.failure : AuthStatus.authenticated,
            user: previous,
            message:
                'Не удалось загрузить профиль. Проверьте подключение и повторите.',
          ),
        );
      }
    }
  }

  Future<void> login(String phone, String password) async {
    if (isClosed || state.status == AuthStatus.loading) return;
    final request = ++_request;
    emit(const AuthState(AuthStatus.loading));
    try {
      final user = await _repository.login(phone: phone, password: password);
      if (!isClosed && request == _request) {
        emit(AuthState(AuthStatus.authenticated, user: user));
      }
    } catch (error) {
      if (!isClosed && request == _request) {
        emit(
          AuthState(
            AuthStatus.failure,
            message: error is AppException
                ? error.userMessage
                : 'Не удалось войти. Повторите попытку.',
          ),
        );
      }
    }
  }

  Future<void> logout() async {
    final request = ++_request;
    await _repository.logout();
    if (!isClosed && request == _request) {
      emit(const AuthState(AuthStatus.unauthenticated));
    }
  }
}
