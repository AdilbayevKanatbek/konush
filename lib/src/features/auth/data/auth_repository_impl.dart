import 'package:konush/src/core/storage/token_storage.dart';
import 'package:konush/src/features/auth/data/auth_remote_data_source.dart';
import 'package:konush/src/features/auth/domain/auth_params.dart';
import 'package:konush/src/features/auth/domain/auth_repository.dart';
import 'package:konush/src/features/auth/domain/user.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote, this._tokens);
  final AuthRemoteDataSource _remote;
  final TokenStorage _tokens;

  @override
  Future<User> login({required String phone, required String password}) async {
    final session = await _remote.login(phone: phone, password: password);
    await _tokens.save(session.tokens);
    return session.user;
  }

  @override
  Future<User> register(RegisterParams params) async {
    final session = await _remote.register(params);
    await _tokens.save(session.tokens);
    return session.user;
  }

  @override
  Future<User> getProfile() => _remote.getProfile();

  @override
  Future<void> sendOtp(String phone) => _remote.sendOtp(phone);

  @override
  Future<void> verifyOtp({required String phone, required String code}) =>
      _remote.verifyOtp(phone: phone, code: code);

  @override
  Future<void> requestPasswordReset(String phone) =>
      _remote.requestPasswordReset(phone);

  @override
  Future<String> verifyResetCode({
    required String phone,
    required String code,
  }) => _remote.verifyResetCode(phone: phone, code: code);

  @override
  Future<void> resetPassword(ResetPasswordParams params) =>
      _remote.resetPassword(params);

  @override
  Future<DevOtpCode> getDevOtp(String phone) => _remote.getDevOtp(phone);

  @override
  Future<bool> hasSession() async => await _tokens.refreshToken != null;

  @override
  Future<void> logout() async {
    final refresh = await _tokens.refreshToken;
    try {
      if (refresh != null) await _remote.logout(refresh);
    } catch (_) {
      // The local session still ends when the logout endpoint is offline.
    } finally {
      await _tokens.clear();
    }
  }
}
