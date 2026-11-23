import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../../domain/notification.dart';

class NotificationsCubit extends AsyncCubit<List<AppNotification>> {
  NotificationsCubit(this._repo);
  final NotificationsRepository _repo;
  UserRole _role = UserRole.employee;

  int get unreadCount => (state.data ?? const []).where((n) => !n.read).length;

  Future<void> load([UserRole? role]) {
    _role = role ?? _role;
    return run(() => _repo.fetch(_role));
  }

  Future<void> markRead(String id) async {
    await _repo.markRead(_role, id);
    set(await _repo.fetch(_role));
  }

  Future<void> markAllRead() async {
    await _repo.markAllRead(_role);
    set(await _repo.fetch(_role));
  }
}
