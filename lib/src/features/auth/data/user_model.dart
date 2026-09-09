import 'package:konush/src/features/auth/domain/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.phone,
    required super.name,
    required super.role,
    required super.isVerified,
    required super.isBanned,
    required super.createdAt,
    required super.updatedAt,
    super.email,
    super.avatarUrl,
    super.agencyId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    phone: json['phone'] as String,
    name: json['name'] as String? ?? '',
    email: json['email'] as String?,
    avatarUrl: json['avatar'] as String?,
    role: _roleFromWire(json['role'] as String?),
    isVerified: json['is_verified'] as bool? ?? false,
    isBanned: json['is_banned'] as bool? ?? false,
    agencyId: json['agency_id'] as String?,
    createdAt:
        DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt:
        DateTime.tryParse(json['updated_at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );

  static UserRole _roleFromWire(String? value) => switch (value) {
    'agent' => UserRole.agent,
    'admin' => UserRole.admin,
    _ => UserRole.user,
  };
}
