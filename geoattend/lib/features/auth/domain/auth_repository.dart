import 'package:geoattend/core/core.dart';

abstract class AuthRepository {
  Future<AppUser> login({required String email, required String password, required UserRole role});
  Future<void> register({
    required String name,
    required String email,
    required String employeeId,
    required String password,
  });
  Future<void> sendResetCode(String email);

  /// Returns a short-lived reset token to pass to [resetPassword].
  Future<String> verifyCode({required String email, required String code});
  Future<void> resetPassword({required String token, required String newPassword});

  /// Signed-in user from the stored tokens, or null (used at app start).
  Future<AppUser?> restoreSession();
  Future<void> logout();
  Future<AppUser> updateProfile({String? name, String? phone});
  Future<void> changePassword({required String currentPassword, required String newPassword});
}
