import 'package:geoattend/core/core.dart';

import '../domain/notification.dart';

class MockNotificationsRepository implements NotificationsRepository {
  DateTime _ago(int minutes) => DateTime.now().subtract(Duration(minutes: minutes));

  late final Map<UserRole, List<AppNotification>> _store = {
    UserRole.employee: [
      AppNotification(id: 'n1', type: NotificationType.clockIn, title: 'Clock-In Successful', body: 'Your clock-in was recorded at 8:12 AM', time: _ago(2)),
      AppNotification(id: 'n2', type: NotificationType.leaveApproved, title: 'Leave Request Approved', body: 'Your leave request has been approved', time: _ago(2)),
      AppNotification(id: 'n3', type: NotificationType.correctionRejected, title: 'Correction Request Rejected', body: 'Your correction has been rejected', time: _ago(60), read: true),
      AppNotification(id: 'n4', type: NotificationType.reminder, title: 'Reminder', body: 'Clock-out is in 5 minutes', time: _ago(60)),
    ],
    UserRole.hod: _managerList(),
    UserRole.admin: _managerList(),
  };

  List<AppNotification> _managerList() => [
        AppNotification(id: 'm1', type: NotificationType.leaveRequest, title: 'New Leave Request', body: 'Atabong applied for Leave', time: _ago(120)),
        AppNotification(id: 'm2', type: NotificationType.correctionRequest, title: 'New Correction Request', body: 'Zingwa Rodrick requested correction', time: _ago(60), read: true),
        AppNotification(id: 'm3', type: NotificationType.attendanceAlert, title: 'Attendance Alert', body: 'Emily Doris is late', time: _ago(60)),
        AppNotification(id: 'm4', type: NotificationType.leaveApproved, title: 'Leave Approved', body: 'James Wilson leave approved', time: _ago(60), read: true),
      ];

  @override
  Future<List<AppNotification>> fetch(UserRole role) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List.of(_store[role]!);
  }

  @override
  Future<void> markRead(UserRole role, String id) async {
    final list = _store[role]!;
    final i = list.indexWhere((n) => n.id == id);
    if (i >= 0) list[i] = list[i].asRead();
  }

  @override
  Future<void> markAllRead(UserRole role) async {
    final list = _store[role]!;
    for (var i = 0; i < list.length; i++) {
      list[i] = list[i].asRead();
    }
  }
}
