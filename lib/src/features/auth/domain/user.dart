import 'package:equatable/equatable.dart';

enum UserRole { user, agent, admin }

class User extends Equatable {
  const User({
    required this.id,
    required this.phone,
    required this.name,
    required this.role,
    required this.isVerified,
    required this.isBanned,
    required this.createdAt,
    required this.updatedAt,
    this.email,
    this.avatarUrl,
    this.agencyId,
  });

  final String id;
  final String phone;
  final String name;
  final String? email;
  final String? avatarUrl;
  final UserRole role;
  final bool isVerified;
  final bool isBanned;
  final String? agencyId;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    phone,
    name,
    email,
    avatarUrl,
    role,
    isVerified,
    isBanned,
    agencyId,
    createdAt,
    updatedAt,
  ];
}
