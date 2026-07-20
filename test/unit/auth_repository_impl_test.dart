import 'package:flutter_test/flutter_test.dart';
import 'package:chiromo/features/auth/data/repositories/auth_repository_impl.dart';

void main() {
  group('buildProfileUpsertPayload', () {
    test('normalizes profile fields and preserves the user id', () {
      final payload = buildProfileUpsertPayload(
        userId: 'user-123',
        firstName: '  John ',
        lastName: ' Doe ',
        phone: '0712345678',
        role: 'patient',
      );

      expect(payload['id'], 'user-123');
      expect(payload['first_name'], 'John');
      expect(payload['last_name'], 'Doe');
      expect(payload['phone_number'], '0712345678');
      expect(payload['role'], 'patient');
    });

    test('omits empty values so existing profile data is not overwritten', () {
      final payload = buildProfileUpsertPayload(userId: 'user-456');

      expect(payload, {'id': 'user-456'});
    });
  });
}
