class RegisterParams {
  const RegisterParams({
    required this.phone,
    required this.name,
    required this.password,
    this.email,
    this.role = 'user',
  });

  final String phone;
  final String name;
  final String password;
  final String? email;
  final String role;

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'name': name,
    'password': password,
    if (email?.isNotEmpty == true) 'email': email,
    'role': role,
  };
}

class ResetPasswordParams {
  const ResetPasswordParams({
    required this.phone,
    required this.resetToken,
    required this.newPassword,
  });

  final String phone;
  final String resetToken;
  final String newPassword;

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'reset_token': resetToken,
    'new_password': newPassword,
  };
}

class DevOtpCode {
  const DevOtpCode({
    required this.phone,
    required this.code,
    required this.resetCode,
  });
  final String phone;
  final String code;
  final String resetCode;
}
