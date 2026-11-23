import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../../../attendance/domain/attendance.dart';
import '../../../attendance/presentation/cubit/attendance_cubit.dart';
import '../../../notifications/presentation/cubit/notifications_cubit.dart';

/// Employee dashboard: today's attendance, summary and quick actions.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = sl<SessionController>().user!;
    final unread = context.watch<NotificationsCubit>().unreadCount;
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Column(children: [
        _Header(user: user, hasUnread: unread > 0),
        Expanded(
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: AsyncBuilder<AttendanceCubit, AttendanceData>(
              onRetry: () => context.read<AttendanceCubit>().load(),
              builder: (context, data) => _HomeBody(data: data, user: user, unread: unread),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user, required this.hasUnread});
  final AppUser user;
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.location_on, color: Colors.white, size: 30),
          const SizedBox(width: 6),
          const Text('GeoAttend', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w500)),
          const Spacer(),
          GestureDetector(
            onTap: () => context.go(R.tab(UserRole.employee, 'notifications')),
            child: Stack(children: [
              const Icon(Icons.notifications_none, color: Colors.white, size: 28),
              if (hasUnread)
                Positioned(
                  right: 2, top: 2,
                  child: Container(width: 10, height: 10,
                      decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle)),
                ),
            ]),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: () => context.go(R.tab(UserRole.employee, 'profile')),
            child: Container(
              width: 52, height: 52,
              decoration: const BoxDecoration(color: Color(0xFFD9D9D9), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(Fmt.initials(user.name), style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
        const SizedBox(height: 18),
        Text('${Fmt.greeting()}, 👋', style: const TextStyle(color: Colors.white, fontSize: 14)),
        Text(user.firstName, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text('Today is ${Fmt.dateFull(DateTime.now())}', style: const TextStyle(color: Colors.white, fontSize: 13)),
      ]),
    );
  }
}

class _HomeBody extends StatefulWidget {
  const _HomeBody({required this.data, required this.user, required this.unread});
  final AttendanceData data;
  final AppUser user;
  final int unread;

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final issues = await sl<AttendanceRepository>().takeSyncIssues();
      if (!mounted || issues.isEmpty) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('An offline record was not accepted: ${issues.first}'),
        duration: const Duration(seconds: 8),
      ));
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final today = data.today;
    final target = const Duration(minutes: AppConfig.targetWorkMinutes);
    final worked = today?.clockIn == null
        ? Duration.zero
        : (today!.clockOut ?? DateTime.now()).difference(today.clockIn!);
    final remaining = worked >= target ? Duration.zero : target - worked;
    final role = UserRole.employee;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
      children: [
        _attendanceCard(context, data),
        const SizedBox(height: 14),
        _workdayBanner(),
        const SizedBox(height: 14),
        _summaryCard(target, worked, remaining),
        const SizedBox(height: 22),
        const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        Wrap(spacing: 12, runSpacing: 12, children: [
          QuickActionTile(icon: Icons.calendar_month_outlined, label: 'Attendance\nHistory',
              onTap: () => context.go(R.tab(role, 'attendance'))),
          QuickActionTile(icon: Icons.beach_access_outlined, label: 'Leave\nRequest',
              onTap: () => context.push(R.leaveNew)),
          QuickActionTile(icon: Icons.edit_note, label: 'Correction\nRequest',
              onTap: () => context.push(R.correctionNew)),
          QuickActionTile(icon: Icons.notifications_none, label: 'Notifications', badge: widget.unread,
              onTap: () => context.go(R.tab(role, 'notifications'))),
          QuickActionTile(icon: Icons.person_outline, label: 'Profile',
              onTap: () => context.go(R.tab(role, 'profile'))),
          QuickActionTile(icon: Icons.settings_outlined, label: 'Settings',
              onTap: () => context.push(R.settings)),
        ]),
      ],
    );
  }

  Widget _attendanceCard(BuildContext context, AttendanceData data) {
    final today = data.today;
    final Widget pill = switch (today?.status) {
      null => const StatusPill('Not clocked in', color: AppColors.textSecondary, background: Color(0xFFE5E5E5)),
      AttendanceStatus.late => const StatusPill('Late', color: Colors.white, background: AppColors.amber),
      _ => const StatusPill('On Time', color: Colors.white, background: AppColors.green),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Today’s Attendance', style: TextStyle(fontWeight: FontWeight.w500)),
          pill,
        ]),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _timeBlock('Clock In', Fmt.time(today?.clockIn)),
          _timeBlock('Clock Out', Fmt.time(today?.clockOut)),
        ]),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _mini(Icons.check, AppColors.green, AppColors.greenSoft, 'Status', today?.status.label ?? 'Not yet'),
          _mini(Icons.location_on_outlined, AppColors.navy, AppColors.skyBlue, 'Workplace',
              today?.workplace ?? widget.user.workplace),
          _mini(Icons.my_location, AppColors.textSecondary, const Color(0xFFE5E5E5), 'Geofence',
              today == null ? 'Not checked' : 'Within Range'),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: _ClockButton(
              label: 'Clock In', filled: true, enabled: !data.hasClockedIn,
              onTap: () => context.push(R.verifyLocationOf('in')),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _ClockButton(
              label: 'Clock Out', filled: false, enabled: data.hasClockedIn && !data.hasClockedOut,
              onTap: () => context.push(R.verifyLocationOf('out')),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _timeBlock(String label, String value) => Row(children: [
        Container(
          width: 30, height: 30,
          decoration: const BoxDecoration(color: Color(0xFFD9D9D9), shape: BoxShape.circle),
          child: const Icon(Icons.access_time, size: 16),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ]),
      ]);

  Widget _mini(IconData icon, Color color, Color bg, String label, String value) => Row(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 10)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ]),
      ]);

  Widget _workdayBanner() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.amberSoft, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          const Icon(Icons.wb_sunny_outlined, color: AppColors.amber, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Your workday ends at ${AppConfig.workEndHour - 12}:00 PM',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              const Text('Don’t forget to clock out',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
          const Icon(Icons.chevron_right),
        ]),
      );

  Widget _summaryCard(Duration target, Duration worked, Duration remaining) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.navy),
            SizedBox(width: 8),
            Text('Today’s Summary', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(children: [
              _stat(Fmt.duration(target), 'Working Hours'),
              const VerticalDivider(color: AppColors.textSecondary, width: 1),
              _stat(Fmt.duration(worked), 'Time worked'),
              const VerticalDivider(color: AppColors.textSecondary, width: 1),
              _stat(Fmt.duration(remaining), 'Remaining'),
            ]),
          ),
        ]),
      );

  Widget _stat(String value, String label) => Expanded(
        child: Column(children: [
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ]),
      );
}

class _ClockButton extends StatelessWidget {
  const _ClockButton({required this.label, required this.filled, required this.enabled, required this.onTap});
  final String label;
  final bool filled;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : Colors.black;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: filled ? AppColors.navy : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: enabled ? onTap : null,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: filled ? null : Border.all(color: Colors.black87),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.access_time, size: 20, color: fg),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 13, color: fg)),
            ]),
          ),
        ),
      ),
    );
  }
}
