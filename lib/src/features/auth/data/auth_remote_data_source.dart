import 'package:konush/src/core/config/app_config.dart';
import 'package:konush/src/core/network/api_client.dart';
import 'package:konush/src/core/storage/token_storage.dart';
import 'package:konush/src/features/auth/data/user_model.dart';
import 'package:konush/src/features/auth/domain/auth_params.dart';

class AuthSessionModel {
  const AuthSessionModel({required this.user, required this.tokens});
  final UserModel user;
  final TokenPair tokens;

  factory AuthSessionModel.fromJson(Object? value) {
    final json = value! as Map<String, dynamic>;
    final tokens = json['tokens'] as Map<String, dynamic>;
    return AuthSessionModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      tokens: TokenPair(
        accessToken: tokens['access_token'] as String,
        refreshToken: tokens['refresh_token'] as String,
        expiresIn: tokens['expires_in'] as int? ?? 900,
      ),
    );
  }
}

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._client);
  final ApiClient _client;

  Future<AuthSessionModel> login({
    required String phone,
    required String password,
  }) async {
    final response = await _client.post(
      '/auth/login',
      data: {'phone': phone, 'password': password},
      decode: AuthSessionModel.fromJson,
    );
    return response.data;
  }

  Future<AuthSessionModel> register(RegisterParams params) async {
    final response = await _client.post(
      '/auth/register',
      data: params.toJson(),
      decode: AuthSessionModel.fromJson,
    );
    return response.data;
  }

  Future<UserModel> getProfile() async {
    final response = await _client.get(
      '/profile',
      decode: (value) => UserModel.fromJson(value! as Map<String, dynamic>),
    );
    return response.data;
  }

  Future<void> sendOtp(String phone) =>
      _postMessage('/auth/otp/send', {'phone': phone});

  Future<void> verifyOtp({required String phone, required String code}) =>
      _postMessage('/auth/otp/verify', {'phone': phone, 'code': code});

  Future<void> requestPasswordReset(String phone) =>
      _postMessage('/auth/password/forgot', {'phone': phone});

  Future<String> verifyResetCode({
    required String phone,
    required String code,
  }) async {
    final response = await _client.post(
      '/auth/password/verify-code',
      data: {'phone': phone, 'code': code},
      decode: (value) =>
          (value! as Map<String, dynamic>)['reset_token'] as String,
    );
    return response.data;
  }

  Future<void> resetPassword(ResetPasswordParams params) =>
      _postMessage('/auth/password/reset', params.toJson());

  Future<DevOtpCode> getDevOtp(String phone) async {
    if (!AppConfig.enableDevOtp) {
      throw UnsupportedError('Dev OTP отключён');
    }
    final response = await _client.get(
      '/dev/otp/${Uri.encodeComponent(phone)}',
      decode: (value) {
        final json = value! as Map<String, dynamic>;
        return DevOtpCode(
          phone: json['phone'] as String,
          code: json['code'] as String? ?? '',
          resetCode: json['reset_code'] as String? ?? '',
        );
      },
    );
    return response.data;
  }

  Future<void> logout(String refreshToken) =>
      _postMessage('/auth/logout', {'refresh_token': refreshToken});

  Future<void> _postMessage(String path, Map<String, dynamic> data) async {
    await _client.post<Map<String, dynamic>>(
      path,
      data: data,
      decode: (value) => value! as Map<String, dynamic>,
    );
  }
}
