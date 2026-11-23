import 'package:geoattend/core/core.dart';

import '../../../core/network/api_client.dart';
import '../domain/notification.dart';

/// The server knows who is asking, so the role argument is not needed.
class RemoteNotificationsRepository implements NotificationsRepository {
  RemoteNotificationsRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<AppNotification>> fetch(UserRole role) async {
    final data = await _api.send(() => _api.dio.get<dynamic>('/notifications'));
    return [for (final n in data as List) AppNotification.fromJson(n as Map<String, dynamic>)];
  }

  @override
  Future<void> markRead(UserRole role, String id) async {
    await _api.send(() => _api.dio.post<dynamic>('/notifications/$id/read'));
  }

  @override
  Future<void> markAllRead(UserRole role) async {
    await _api.send(() => _api.dio.post<dynamic>('/notifications/read-all'));
  }
}
