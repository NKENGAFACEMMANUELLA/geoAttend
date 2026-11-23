import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../../../leave/domain/leave.dart';
import '../../../notifications/presentation/cubit/notifications_cubit.dart';
import '../../../leave/presentation/cubit/leave_cubit.dart';
import '../../domain/team.dart';
import '../cubit/team_attendance_cubit.dart';
import '../widgets/team_attendance_view.dart';

/// HOD "Attendance" tab.
class DepartmentAttendancePage extends StatelessWidget {
  const DepartmentAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final dept = sl<SessionController>().user?.department;
    return AppPage(
      title: 'Attendance',
      showBack: false,
      child: TeamAttendanceView(department: dept),
    );
  }
}

/// Admin "Attendance" tab.
class OrganisationAttendancePage extends StatelessWidget {
  const OrganisationAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Organisation-wide Attendance',
      showBack: false,
      child: TeamAttendanceView(allowDepartmentFilter: true),
    );
  }
}

class HodDashboardPage extends StatelessWidget {
  const HodDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = sl<SessionController>().user!;
    return BlocProvider(
      create: (_) => TeamAttendanceCubit(sl<TeamRepository>())
        ..load(Fmt.dateOnly(DateTime.now()), department: user.department),
      child: Builder(builder: (context) {
        final unread = context.watch<NotificationsCubit>().unreadCount;
        return DashboardScaffold(
          header: DashboardHeader(
            name: user.name,
            subtitle: 'HOD  |  ${user.department} Department',
            hasUnread: unread > 0,
            onBell: () => context.go(R.tab(UserRole.hod, 'notifications')),
            onAvatar: () => context.go(R.tab(UserRole.hod, 'profile')),
          ),
          child: AsyncBuilder<TeamAttendanceCubit, TeamData>(
            onRetry: () => context.read<TeamAttendanceCubit>().load(Fmt.dateOnly(DateTime.now()), department: user.department),
            builder: (context, data) => _HodBody(data: data),
          ),
        );
      }),
    );
  }
}

class _HodBody extends StatelessWidget {
  const _HodBody({required this.data});
  final TeamData data;

  @override
  Widget build(BuildContext context) {
    final s = data.summary;
    final pending = (context.watch<LeaveCubit>().state.data ?? const LeaveData()).pendingApprovals;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 24), children: [
      SoftCard(
        child: Row(children: [
          DonutProgress(percent: s.rate, size: 106),
          const SizedBox(width: 18),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Attendance rate today', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text('${s.present + s.late} of ${s.total} checked in',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              const Wrap(spacing: 12, runSpacing: 6, children: [
                LegendDot(color: AppColors.greenDark, label: 'Present'),
                LegendDot(color: AppColors.amber, label: 'Late'),
                LegendDot(color: AppColors.red, label: 'Absent'),
              ]),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.9,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          DashStatTile(icon: Icons.check_circle_outline, label: 'Present', value: '${s.present}', color: AppColors.greenDark),
          DashStatTile(icon: Icons.schedule, label: 'Late', value: '${s.late}', color: AppColors.amber),
          DashStatTile(icon: Icons.cancel_outlined, label: 'Absent', value: '${s.absent}', color: AppColors.red),
          DashStatTile(icon: Icons.beach_access_outlined, label: 'On Leave', value: '${s.onLeave}', color: AppColors.navy),
        ],
      ),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(child: DashAction(icon: Icons.fact_check_outlined, label: 'Team\nAttendance', color: AppColors.navy,
            onTap: () => context.go(R.tab(UserRole.hod, 'attendance')))),
        const SizedBox(width: 12),
        Expanded(child: DashAction(icon: Icons.pie_chart_outline, label: 'Daily\nSummary', color: const Color(0xFF6A4CFF),
            onTap: () => context.push(R.dailySummary))),
        const SizedBox(width: 12),
        Expanded(child: DashAction(icon: Icons.edit_note, label: 'Correction\nRequests', color: AppColors.amber,
            onTap: () => context.push(R.hodCorrections))),
        const SizedBox(width: 12),
        Expanded(child: DashAction(icon: Icons.assessment_outlined, label: 'Reports', color: AppColors.greenDark,
            onTap: () => context.go(R.tab(UserRole.hod, 'reports')))),
      ]),
      const SizedBox(height: 22),
      SectionHeader('Today’s team', actionLabel: 'See all', onAction: () => context.go(R.tab(UserRole.hod, 'attendance'))),
      SoftCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(children: [
          if (data.rows.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('No employees in this department yet.')),
          for (var i = 0; i < data.rows.take(5).length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _teamRow(data.rows[i]),
          ],
        ]),
      ),
      const SizedBox(height: 22),
      Row(children: [
        const Text('Pending leave requests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        if (pending.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(10)),
            child: Text('${pending.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
      ]),
      const SizedBox(height: 10),
      if (pending.isEmpty)
        const SoftCard(
          child: Row(children: [
            IconBadge(icon: Icons.task_alt, color: AppColors.greenDark),
            SizedBox(width: 12),
            Expanded(child: Text('You’re all caught up. No requests are waiting for your review.', style: TextStyle(fontSize: 13))),
          ]),
        )
      else
        for (final r in pending)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SoftCard(
              onTap: () => context.push(R.hodLeaveOf(r.id)),
              child: Row(children: [
                AvatarCircle(name: r.employeeName, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.employeeName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${r.type}  |  ${Fmt.dateShort(r.start)} - ${Fmt.dateShort(r.end)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ]),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ]),
            ),
          ),
    ]);
  }

  Widget _teamRow(TeamRow r) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          AvatarCircle(name: r.name, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              Text(r.position, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            StatusPill.attendance(r.status),
            const SizedBox(height: 4),
            Text(r.time == null ? '--' : Fmt.time(r.time), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ]),
      );
}

class DailySummaryPage extends StatelessWidget {
  const DailySummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TeamAttendanceCubit(sl<TeamRepository>()),
      child: const _SummaryBody(),
    );
  }
}

class _SummaryBody extends StatefulWidget {
  const _SummaryBody();

  @override
  State<_SummaryBody> createState() => _SummaryBodyState();
}

class _SummaryBodyState extends State<_SummaryBody> {
  DateTime _date = Fmt.dateOnly(DateTime.now());
  late final String? _dept = sl<SessionController>().user?.department;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => context.read<TeamAttendanceCubit>().load(_date, department: _dept);

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Daily Summary',
      child: Column(children: [
        DateNavigator(date: _date, onChanged: (d) {
          setState(() => _date = Fmt.dateOnly(d));
          _load();
        }),
        Expanded(
          child: AsyncBuilder<TeamAttendanceCubit, TeamData>(
            onRetry: _load,
            builder: (context, data) {
              final s = data.summary;
              Widget row(String label, int n) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(label), Text('$n (${s.percentOf(n)}%)'),
                    ]),
                  );
              return ListView(children: [
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Total Employees', style: TextStyle(fontSize: 16)),
                  Text('${s.total}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 16),
                row('Present', s.present),
                row('Late', s.late),
                row('Absent', s.absent),
                row('On Leave', s.onLeave),
                const SizedBox(height: 32),
                Row(children: [
                  DonutProgress(percent: s.rate, size: 120),
                  const SizedBox(width: 20),
                  const Expanded(child: Text('Attendance Rate', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
                ]),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'View Report',
                  onPressed: () => context.go(R.tab(UserRole.hod, 'reports')),
                ),
              ]);
            },
          ),
        ),
      ]),
    );
  }
}
