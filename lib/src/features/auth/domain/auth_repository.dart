import 'package:konush/src/features/auth/domain/auth_params.dart';
import 'package:konush/src/features/auth/domain/user.dart';

abstract interface class AuthRepository {
  Future<User> login({required String phone, required String password});
  Future<User> register(RegisterParams params);
  Future<User> getProfile();
  Future<void> sendOtp(String phone);
  Future<void> verifyOtp({required String phone, required String code});
  Future<void> requestPasswordReset(String phone);
  Future<String> verifyResetCode({required String phone, required String code});
  Future<void> resetPassword(ResetPasswordParams params);
  Future<DevOtpCode> getDevOtp(String phone);
  Future<bool> hasSession();
  Future<void> logout();
}
