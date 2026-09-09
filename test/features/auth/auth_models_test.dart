import 'package:flutter_test/flutter_test.dart';
import 'package:konush/src/features/auth/data/auth_remote_data_source.dart';
import 'package:konush/src/features/auth/domain/user.dart';

void main() {
  test('AuthSessionModel decodes Swagger AuthResponse with nested tokens', () {
    final session = AuthSessionModel.fromJson({
      'user': {
        'id': 'user-id',
        'phone': '+996700000001',
        'name': 'Азамат',
        'role': 'agent',
        'is_verified': true,
        'is_banned': false,
        'agency_id': 'agency-id',
        'created_at': '2026-08-21T12:00:00Z',
        'updated_at': '2026-08-21T12:00:00Z',
      },
      'tokens': {
        'access_token': 'access',
        'refresh_token': 'refresh',
        'expires_in': 900,
      },
    });

    expect(session.tokens.accessToken, 'access');
    expect(session.tokens.refreshToken, 'refresh');
    expect(session.tokens.expiresIn, 900);
    expect(session.user.role, UserRole.agent);
    expect(session.user.isVerified, isTrue);
    expect(session.user.agencyId, 'agency-id');
  });
}
