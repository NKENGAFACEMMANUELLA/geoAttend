import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../../../notifications/presentation/cubit/notifications_cubit.dart';
import '../../domain/admin.dart';
import '../cubit/admin_cubits.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = sl<SessionController>().user!;
    return BlocProvider(
      create: (_) => AdminOverviewCubit(sl<AdminRepository>())..load(),
      child: Builder(builder: (context) {
        final unread = context.watch<NotificationsCubit>().unreadCount;
        return DashboardScaffold(
          header: DashboardHeader(
            name: user.name,
            subtitle: user.organisation.isEmpty ? 'Administrator' : 'Administrator  |  ${user.organisation}',
            hasUnread: unread > 0,
            onBell: () => context.go(R.tab(UserRole.admin, 'notifications')),
            onAvatar: () => context.go(R.tab(UserRole.admin, 'profile')),
          ),
          child: AsyncBuilder<AdminOverviewCubit, AdminOverview>(
            onRetry: () => context.read<AdminOverviewCubit>().load(),
            builder: (context, o) => _Body(o: o),
          ),
        );
      }),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.o});
  final AdminOverview o;

  String _pct(int n) => o.employees == 0 ? '0%' : '${(n / o.employees * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 24), children: [
      SoftCard(
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Total employees', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${o.employees}', style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w700, color: AppColors.navy, height: 1.15)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(20)),
                child: Text('${o.present + o.late} checked in today', style: const TextStyle(fontSize: 11, color: AppColors.navy)),
              ),
            ]),
          ),
          DonutProgress(percent: o.rate, size: 112),
        ]),
      ),
      const SizedBox(height: 14),
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.9,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          DashStatTile(icon: Icons.check_circle_outline, label: 'Present  |  ${_pct(o.present)}', value: '${o.present}', color: AppColors.greenDark),
          DashStatTile(icon: Icons.schedule, label: 'Late  |  ${_pct(o.late)}', value: '${o.late}', color: AppColors.amber),
          DashStatTile(icon: Icons.cancel_outlined, label: 'Absent  |  ${_pct(o.absent)}', value: '${o.absent}', color: AppColors.red),
          DashStatTile(icon: Icons.beach_access_outlined, label: 'On Leave  |  ${_pct(o.onLeave)}', value: '${o.onLeave}', color: AppColors.navy),
        ],
      ),
      const SizedBox(height: 22),
      const Text('Manage', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.35,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          DashAction(icon: Icons.groups_outlined, label: 'Employees', subtitle: 'Add and manage staff', color: AppColors.navy, onTap: () => context.push(R.employees)),
          DashAction(icon: Icons.apartment, label: 'Departments', subtitle: 'Teams and their HODs', color: const Color(0xFF6A4CFF), onTap: () => context.push(R.departments)),
          DashAction(icon: Icons.location_city, label: 'Workplaces', subtitle: 'Offices and sites', color: AppColors.greenDark, onTap: () => context.push(R.workplaces)),
          DashAction(icon: Icons.my_location, label: 'Geofence', subtitle: 'Set clock-in areas', color: AppColors.amber, onTap: () => context.push(R.geofence)),
          DashAction(icon: Icons.event_available, label: 'Leave approvals', subtitle: 'HR review stage', color: const Color(0xFFD81B60), onTap: () => context.push(R.adminLeave)),
          DashAction(icon: Icons.assessment_outlined, label: 'Reports', subtitle: 'Attendance reports', color: AppColors.navy, onTap: () => context.go(R.tab(UserRole.admin, 'reports'))),
        ],
      ),
      const SizedBox(height: 22),
      SectionHeader('Recent attendance', actionLabel: 'View all', onAction: () => context.go(R.tab(UserRole.admin, 'attendance'))),
      SoftCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(children: [
          for (var i = 0; i < o.recent.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                AvatarCircle(name: o.recent[i].name, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(o.recent[i].name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    Text(o.recent[i].employeeId, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  StatusPill.attendance(o.recent[i].status),
                  const SizedBox(height: 4),
                  Text(o.recent[i].time == null ? '--' : Fmt.time(o.recent[i].time),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ]),
              ]),
            ),
          ],
        ]),
      ),
    ]);
  }
}
