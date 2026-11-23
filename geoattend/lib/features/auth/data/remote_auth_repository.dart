import 'package:dio/dio.dart';
import 'package:geoattend/core/core.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/token_storage.dart';
import '../domain/auth_repository.dart';

/// Talks to the GeoAttend API (/api/v1/auth/*).
class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository(this._api, this._tokens);
  final ApiClient _api;
  final TokenStorage _tokens;

  Dio get _dio => _api.dio;

  Future<AppUser> _startSession(dynamic data) async {
    final m = data as Map<String, dynamic>;
    await _tokens.save(access: m['accessToken'] as String, refresh: m['refreshToken'] as String);
    return AppUser.fromJson(m['user'] as Map<String, dynamic>);
  }

  @override
  Future<AppUser> login({required String email, required String password, required UserRole role}) async {
    final data = await _api.send(() => _dio.post<dynamic>(
          '/auth/login',
          data: {'email': email, 'password': password, 'portal': role.name},
          options: ApiClient.noAuth,
        ));
    return _startSession(data);
  }

  @override
  Future<void> register({required String name, required String email, required String employeeId, required String password}) async {
    await _api.send(() => _dio.post<dynamic>(
          '/auth/register',
          data: {'name': name, 'email': email, 'employeeId': employeeId, 'password': password},
          options: ApiClient.noAuth,
        ));
  }

  @override
  Future<void> sendResetCode(String email) async {
    await _api.send(() => _dio.post<dynamic>('/auth/forgot', data: {'email': email}, options: ApiClient.noAuth));
  }

  @override
  Future<String> verifyCode({required String email, required String code}) async {
    final data = await _api.send(() =>
        _dio.post<dynamic>('/auth/verify-code', data: {'email': email, 'code': code}, options: ApiClient.noAuth));
    return (data as Map)['resetToken'] as String;
  }

  @override
  Future<void> resetPassword({required String token, required String newPassword}) async {
    await _api.send(() => _dio.post<dynamic>(
          '/auth/reset',
          data: {'resetToken': token, 'newPassword': newPassword},
          options: ApiClient.noAuth,
        ));
  }

  @override
  Future<AppUser?> restoreSession() async {
    if (await _tokens.refreshToken == null) return null;
    try {
      final data = await _api.send(() => _dio.get<dynamic>('/auth/me'));
      return AppUser.fromJson(data as Map<String, dynamic>);
    } on AppException {
      return null; // expired, offline or server asleep: show the login screen
    }
  }

  @override
  Future<void> logout() async {
    final refresh = await _tokens.refreshToken;
    await _tokens.clear();
    if (refresh == null) return;
    try {
      await _dio.post<dynamic>('/auth/logout', data: {'refreshToken': refresh}, options: ApiClient.noAuth);
    } catch (_) {
      // Best effort: the token is already gone from this device.
    }
  }

  @override
  Future<AppUser> updateProfile({String? name, String? phone}) async {
    final data = await _api.send(() => _dio.patch<dynamic>('/auth/me', data: {
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
        }));
    return AppUser.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    final data = await _api.send(() => _dio.post<dynamic>(
          '/auth/change-password',
          data: {'currentPassword': currentPassword, 'newPassword': newPassword},
        ));
    await _startSession(data); // server signs other devices out and returns fresh tokens
  }
}
