import 'package:geoattend/core/core.dart';

import '../domain/auth_repository.dart';

/// Offline mock. Use with: flutter run --dart-define=USE_MOCK_AUTH=true
class MockAuthRepository implements AuthRepository {
  Future<void> _wait() => Future<void>.delayed(const Duration(milliseconds: 700));

  @override
  Future<AppUser> login({required String email, required String password, required UserRole role}) async {
    await _wait();
    return switch (role) {
      UserRole.employee => AppUser(
          id: 'u-emp', name: 'Emmanuella Atefaec', email: email, role: role,
          phone: '+237 677 000 013', employeeId: 'EMP0013', department: 'IT',
          position: 'Software Engineer', workplace: 'Main Office'),
      UserRole.hod => AppUser(
          id: 'u-hod', name: 'James Wilson', email: email, role: role,
          phone: '+237 677 000 002', department: 'Sales', position: 'HOD/Officer',
          workplace: 'Main Office'),
      UserRole.admin => AppUser(
          id: 'u-admin', name: 'Admin', email: email, role: role,
          phone: '+237 677 000 001', position: 'Administrator', organisation: 'TTNet LTD'),
    };
  }

  @override
  Future<void> register({required String name, required String email, required String employeeId, required String password}) => _wait();

  @override
  Future<void> sendResetCode(String email) => _wait();

  @override
  Future<String> verifyCode({required String email, required String code}) async {
    await _wait();
    if (!RegExp(r'^\d{4}$').hasMatch(code)) throw AppException('Enter the 4-digit code we sent you.');
    return 'mock-reset-token';
  }

  @override
  Future<void> resetPassword({required String token, required String newPassword}) => _wait();

  @override
  Future<AppUser?> restoreSession() async => null;

  @override
  Future<void> logout() async {}

  @override
  Future<AppUser> updateProfile({String? name, String? phone}) async {
    await _wait();
    return sl<SessionController>().user!.copyWith(name: name, phone: phone);
  }

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) => _wait();
}
