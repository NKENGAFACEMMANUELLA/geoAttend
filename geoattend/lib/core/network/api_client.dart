import 'dart:async';

import 'package:dio/dio.dart';
import 'package:geoattend/core/core.dart';

import 'token_storage.dart';

/// Dio wrapper: adds the bearer token, refreshes it once on 401, and turns
/// network/server errors into [AppException]s the screens already understand.
class ApiClient {
  ApiClient(this._tokens, this._session) {
    // Long timeouts on purpose: a free server can take ~60 s to wake up.
    final options = BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Accept': 'application/json'},
    );
    dio = Dio(options);
    _refreshDio = Dio(options);
    dio.interceptors.add(InterceptorsWrapper(onRequest: _onRequest, onError: _onError));
  }

  late final Dio dio;
  late final Dio _refreshDio;
  final TokenStorage _tokens;
  final SessionController _session;
  Future<bool>? _refreshing;

  /// Pass as `options:` for calls that must not carry a token (login, register...).
  static Options get noAuth => Options(extra: {'noAuth': true});

  /// Runs [call] and returns the `data` field of the response envelope.
  Future<dynamic> send(Future<Response<dynamic>> Function() call) async {
    try {
      final r = await call();
      final body = r.data;
      return (body is Map && body.containsKey('data')) ? body['data'] : body;
    } on DioException catch (e) {
      throw _toAppException(e);
    }
  }

  Future<void> _onRequest(RequestOptions o, RequestInterceptorHandler handler) async {
    if (o.extra['noAuth'] != true) {
      final token = await _tokens.accessToken;
      if (token != null) o.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(o);
  }

  Future<void> _onError(DioException e, ErrorInterceptorHandler handler) async {
    final o = e.requestOptions;
    final expired = e.response?.statusCode == 401;
    if (!expired || o.extra['noAuth'] == true || o.extra['retried'] == true) {
      return handler.next(e);
    }
    // Several requests can fail at once; they all wait for the same refresh.
    final ok = await (_refreshing ??= _refresh().whenComplete(() => _refreshing = null));
    if (!ok) return handler.next(e);
    try {
      o.extra['retried'] = true;
      o.headers['Authorization'] = 'Bearer ${await _tokens.accessToken}';
      handler.resolve(await dio.fetch<dynamic>(o));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<bool> _refresh() async {
    final refresh = await _tokens.refreshToken;
    if (refresh == null) return false;
    try {
      final r = await _refreshDio.post<dynamic>('/auth/refresh', data: {'refreshToken': refresh});
      final data = (r.data as Map)['data'] as Map;
      await _tokens.save(access: data['accessToken'] as String, refresh: data['refreshToken'] as String);
      return true;
    } on DioException catch (e) {
      // Only end the session if the server rejected the token (not when offline).
      if (e.response?.statusCode == 401) {
        await _tokens.clear();
        _session.signOut();
      }
      return false;
    }
  }

  AppException _toAppException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppException('The server is taking too long to respond. It may be waking up, please try again in a moment.');
      case DioExceptionType.connectionError:
        return NoConnectionException();
      case DioExceptionType.badResponse:
        final body = e.response?.data;
        final message = body is Map ? body['message'] : null;
        return AppException(message is String && message.isNotEmpty
            ? message
            : 'Something went wrong (${e.response?.statusCode}).');
      default:
        return AppException('Something went wrong. Please try again.');
    }
  }
}
