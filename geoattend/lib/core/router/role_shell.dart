import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend/core/core.dart';

import '../../features/admin/presentation/cubit/admin_cubits.dart';
import '../../features/attendance/presentation/cubit/attendance_cubit.dart';
import '../../features/correction/presentation/cubit/correction_cubit.dart';
import '../../features/leave/presentation/cubit/leave_cubit.dart';
import '../../features/notifications/presentation/cubit/notifications_cubit.dart';
import '../../features/workplace/presentation/cubit/workplaces_cubit.dart';

/// Bottom navigation (Home, Attendance, Reports, Notifications, Profile) for
/// one role. The active tab always follows the current route.
class RoleShell extends StatefulWidget {
  const RoleShell({super.key, required this.role, required this.shell});
  final UserRole role;
  final StatefulNavigationShell shell;

  @override
  State<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<RoleShell> {
  @override
  void initState() {
    super.initState();
    final role = widget.role;
    context.read<NotificationsCubit>().load(role);
    switch (role) {
      case UserRole.employee:
        context.read<AttendanceCubit>().load();
        context.read<LeaveCubit>().load(role);
        context.read<CorrectionCubit>().load();
      case UserRole.hod:
        context.read<LeaveCubit>().load(role);
        context.read<CorrectionApprovalsCubit>().load();
      case UserRole.admin:
        context.read<LeaveCubit>().load(role);
        context.read<EmployeesCubit>().load();
        context.read<DepartmentsCubit>().load();
        context.read<WorkplacesCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationsCubit>().unreadCount;
    final items = <(IconData, IconData, String)>[
      (Icons.home_outlined, Icons.home_rounded, 'Home'),
      (Icons.check_circle_outline, Icons.check_circle, 'Attendance'),
      widget.role == UserRole.employee
          ? (Icons.assignment_outlined, Icons.assignment, 'Requests')
          : (Icons.assessment_outlined, Icons.assessment, 'Reports'),
      (Icons.notifications_none, Icons.notifications, 'Notifications'),
      (Icons.person_outline, Icons.person, 'Profile'),
    ];
    final current = widget.shell.currentIndex;
    return Scaffold(
      body: widget.shell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => widget.shell.goBranch(i, initialLocation: i == current),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Stack(clipBehavior: Clip.none, children: [
                        Icon(i == current ? items[i].$2 : items[i].$1,
                            size: 26, color: i == current ? AppColors.navy : Colors.black),
                        if (i == 3 && unread > 0)
                          Positioned(
                            right: -2, top: -2,
                            child: Container(
                              width: 9, height: 9,
                              decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle),
                            ),
                          ),
                      ]),
                      const SizedBox(height: 4),
                      Text(items[i].$3,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: i == current ? FontWeight.w600 : FontWeight.w500,
                            color: i == current ? AppColors.navy : Colors.black,
                          )),
                    ]),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
