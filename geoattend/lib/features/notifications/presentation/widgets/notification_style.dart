import 'package:flutter/material.dart';
import 'package:geoattend/core/core.dart';

import '../../domain/notification.dart';

class NotificationStyle {
  const NotificationStyle(this.icon, this.color, this.background);
  final IconData icon;
  final Color color;
  final Color background;

  /// Neutral icons for "new request" items, green/red only for decisions.
  static NotificationStyle of(NotificationType t) => switch (t) {
        NotificationType.clockIn => const NotificationStyle(Icons.check, Colors.white, AppColors.green),
        NotificationType.leaveApproved => const NotificationStyle(Icons.calendar_today_outlined, AppColors.green, AppColors.greenSoft),
        NotificationType.leaveRejected => const NotificationStyle(Icons.event_busy, AppColors.red, AppColors.redSoft),
        NotificationType.correctionApproved => const NotificationStyle(Icons.edit_note, AppColors.green, AppColors.greenSoft),
        NotificationType.correctionRejected => const NotificationStyle(Icons.close, AppColors.red, AppColors.redSoft),
        NotificationType.reminder => const NotificationStyle(Icons.notifications_none, Colors.white, AppColors.amber),
        NotificationType.attendanceAlert => const NotificationStyle(Icons.notifications_none, Colors.white, AppColors.amber),
        NotificationType.leaveRequest => const NotificationStyle(Icons.calendar_today_outlined, Colors.white, AppColors.navy),
        NotificationType.correctionRequest => const NotificationStyle(Icons.edit_note, Colors.white, AppColors.navy),
      };
}
