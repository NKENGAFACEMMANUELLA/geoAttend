import 'package:geoattend/core/core.dart';

enum NotificationType {
  clockIn, leaveRequest, leaveApproved, leaveRejected,
  correctionRequest, correctionApproved, correctionRejected, reminder, attendanceAlert,
}

NotificationType notificationTypeFromApi(String v) => switch (v) {
      'clock_in' => NotificationType.clockIn,
      'leave_request' => NotificationType.leaveRequest,
      'leave_approved' => NotificationType.leaveApproved,
      'leave_rejected' => NotificationType.leaveRejected,
      'correction_request' => NotificationType.correctionRequest,
      'correction_approved' => NotificationType.correctionApproved,
      'correction_rejected' => NotificationType.correctionRejected,
      'attendance_alert' => NotificationType.attendanceAlert,
      _ => NotificationType.reminder,
    };

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    this.read = false,
  });
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime time;
  final bool read;

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        type: notificationTypeFromApi(j['type'] as String),
        title: j['title'] as String,
        body: j['message'] as String,
        time: DateTime.parse(j['createdAt'] as String).toLocal(),
        read: (j['read'] as bool?) ?? false,
      );

  AppNotification asRead() =>
      AppNotification(id: id, type: type, title: title, body: body, time: time, read: true);
}

abstract class NotificationsRepository {
  Future<List<AppNotification>> fetch(UserRole role);
  Future<void> markRead(UserRole role, String id);
  Future<void> markAllRead(UserRole role);
}
