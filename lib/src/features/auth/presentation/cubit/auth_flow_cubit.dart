import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konush/src/core/error/app_exception.dart';
import 'package:konush/src/features/auth/domain/auth_params.dart';
import 'package:konush/src/features/auth/domain/auth_repository.dart';

enum AuthFlowStatus { idle, loading, success, failure }

class AuthFlowState extends Equatable {
  const AuthFlowState({
    this.status = AuthFlowStatus.idle,
    this.message,
    this.resetToken,
    this.devCode,
  });

  final AuthFlowStatus status;
  final String? message;
  final String? resetToken;
  final String? devCode;

  @override
  List<Object?> get props => [status, message, resetToken, devCode];
}

class AuthFlowCubit extends Cubit<AuthFlowState> {
  AuthFlowCubit(this._repository) : super(const AuthFlowState());
  final AuthRepository _repository;

  Future<bool> register(RegisterParams params) =>
      _run(() => _repository.register(params));

  Future<bool> sendVerificationCode(String phone) => _run(() async {
    await _repository.sendOtp(phone);
    await _loadDevCode(phone, reset: false);
  });

  Future<bool> verifyPhone(String phone, String code) =>
      _run(() => _repository.verifyOtp(phone: phone, code: code));

  Future<bool> requestPasswordReset(String phone) => _run(() async {
    await _repository.requestPasswordReset(phone);
    await _loadDevCode(phone, reset: true);
  });

  Future<bool> verifyResetCode(String phone, String code) async {
    if (isClosed || state.status == AuthFlowStatus.loading) return false;
    _safeEmit(const AuthFlowState(status: AuthFlowStatus.loading));
    try {
      final token = await _repository.verifyResetCode(phone: phone, code: code);
      _safeEmit(
        AuthFlowState(status: AuthFlowStatus.success, resetToken: token),
      );
      return true;
    } catch (error) {
      _safeEmit(
        AuthFlowState(status: AuthFlowStatus.failure, message: _message(error)),
      );
      return false;
    }
  }

  Future<bool> resetPassword(ResetPasswordParams params) =>
      _run(() => _repository.resetPassword(params));

  Future<void> _loadDevCode(String phone, {required bool reset}) async {
    try {
      final value = await _repository.getDevOtp(phone);
      _safeEmit(
        AuthFlowState(
          status: AuthFlowStatus.success,
          devCode: reset ? value.resetCode : value.code,
        ),
      );
    } on UnsupportedError {
      _safeEmit(const AuthFlowState(status: AuthFlowStatus.success));
    } catch (_) {
      _safeEmit(const AuthFlowState(status: AuthFlowStatus.success));
    }
  }

  Future<bool> _run(Future<void> Function() operation) async {
    if (isClosed || state.status == AuthFlowStatus.loading) return false;
    _safeEmit(const AuthFlowState(status: AuthFlowStatus.loading));
    try {
      await operation();
      if (state.status == AuthFlowStatus.loading) {
        _safeEmit(const AuthFlowState(status: AuthFlowStatus.success));
      }
      return true;
    } catch (error) {
      _safeEmit(
        AuthFlowState(status: AuthFlowStatus.failure, message: _message(error)),
      );
      return false;
    }
  }

  String _message(Object error) => error is AppException
      ? error.userMessage
      : error.toString().replaceFirst('Exception: ', '');
  void _safeEmit(AuthFlowState value) {
    if (!isClosed) super.emit(value);
  }
}
