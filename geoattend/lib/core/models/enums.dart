import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

enum ViewStatus { loading, loaded, offline, error }

enum AttendanceStatus { present, late, absent, leave }

extension AttendanceStatusX on AttendanceStatus {
  String get label => switch (this) {
        AttendanceStatus.present => 'Present',
        AttendanceStatus.late => 'Late',
        AttendanceStatus.absent => 'Absent',
        AttendanceStatus.leave => 'On Leave',
      };
  Color get color => switch (this) {
        AttendanceStatus.present => AppColors.greenDark,
        AttendanceStatus.late => AppColors.amber,
        AttendanceStatus.absent => AppColors.red,
        AttendanceStatus.leave => AppColors.navy,
      };
  Color get background => switch (this) {
        AttendanceStatus.present => AppColors.greenSoft,
        AttendanceStatus.late => AppColors.amberSoft,
        AttendanceStatus.absent => AppColors.redSoft,
        AttendanceStatus.leave => AppColors.skyBlue,
      };
}

enum RequestStatus { pending, approved, rejected }

extension RequestStatusX on RequestStatus {
  String get label => switch (this) {
        RequestStatus.pending => 'Pending',
        RequestStatus.approved => 'Approved',
        RequestStatus.rejected => 'Rejected',
      };
  Color get color => switch (this) {
        RequestStatus.pending => const Color(0xFFE0B400),
        RequestStatus.approved => AppColors.green,
        RequestStatus.rejected => AppColors.red,
      };
  Color get background => switch (this) {
        RequestStatus.pending => AppColors.amberSoft,
        RequestStatus.approved => AppColors.greenSoft,
        RequestStatus.rejected => AppColors.redSoft,
      };
}
