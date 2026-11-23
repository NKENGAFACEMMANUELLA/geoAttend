import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the access and refresh tokens in the Keychain (iOS) / Keystore (Android).
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage]) : _s = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _s;

  static const _access = 'geoattend_access_token';
  static const _refresh = 'geoattend_refresh_token';

  Future<String?> get accessToken => _s.read(key: _access);
  Future<String?> get refreshToken => _s.read(key: _refresh);

  Future<void> save({required String access, required String refresh}) async {
    await _s.write(key: _access, value: access);
    await _s.write(key: _refresh, value: refresh);
  }

  Future<void> clear() async {
    await _s.delete(key: _access);
    await _s.delete(key: _refresh);
  }
}
