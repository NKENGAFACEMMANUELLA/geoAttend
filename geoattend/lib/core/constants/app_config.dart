import 'package:flutter/foundation.dart';

/// App-wide switches and workday rules.
class AppConfig {
  AppConfig._();

  /// When true, the GPS reading is simulated ~11 m from the workplace so the
  /// clock-in flow can be demoed on an emulator. Set to false for real GPS.
  static const useMockLocation = true;

  /// Workday rules used by the mock repository and the home summary.
  static const workStartHour = 8;
  static const workEndHour = 17;
  static const lateGraceMinutes = 15;
  static const targetWorkMinutes = 8 * 60;

  /// Everything talks to the real API by default. Fall back to offline mock data with:
  ///   --dart-define=USE_MOCK=true            (all of it)
  ///   --dart-define=USE_MOCK_AUTH=true       (login, register, password reset, profile)
  ///   --dart-define=USE_MOCK_ADMIN=true      (employees, departments, workplaces, overview)
  ///   --dart-define=USE_MOCK_OPS=true        (attendance, leave, corrections, notifications, reports)
  static const _mockAll = bool.fromEnvironment('USE_MOCK');
  static const useMockAuth = _mockAll || bool.fromEnvironment('USE_MOCK_AUTH');
  static const useMockAdmin =
      _mockAll || bool.fromEnvironment('USE_MOCK_ADMIN');
  static const useMockOps = _mockAll || bool.fromEnvironment('USE_MOCK_OPS');

  /// Override with --dart-define=API_URL=https://your-api.onrender.com/api/v1
  static const _apiUrlOverride = String.fromEnvironment('API_URL');

  static String get apiBaseUrl {
    if (_apiUrlOverride.isNotEmpty) return _apiUrlOverride;
    // Android emulator reaches your computer at 10.0.2.2; iOS simulator at localhost.
    return (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
        ? 'http://10.0.2.2:3000/api/v1'
        : 'http://localhost:3000/api/v1';
  }

  static const mapTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const packageName = 'com.example.geoattend';
}
