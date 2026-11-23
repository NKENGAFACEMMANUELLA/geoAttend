import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../../domain/attendance.dart';
import '../cubit/attendance_cubit.dart';
import '../widgets/attendance_calendar.dart';

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Attendance History',
      showBack: false,
      child: AsyncBuilder<AttendanceCubit, AttendanceData>(
        onRetry: () => context.read<AttendanceCubit>().load(),
        builder: (context, data) {
          if (data.history.isEmpty) {
            return const EmptyStateView(
              icon: Icons.manage_search_rounded,
              title: 'No attendance records found',
              message: 'Your Attendance History will appear here once you start clocking in.',
            );
          }
          final records = data.history
              .where((r) => r.date.year == _month.year && r.date.month == _month.month)
              .toList();
          final byDay = {for (final r in records) r.date.day: r.status};
          return ListView(children: [
            AttendanceCalendar(
              month: _month,
              statusByDay: byDay,
              selected: _selected,
              onMonthChanged: (m) => setState(() => _month = DateTime(m.year, m.month)),
              onDaySelected: (d) {
                setState(() => _selected = d);
                final match = records.where((r) => Fmt.sameDay(r.date, d));
                if (match.isNotEmpty) context.push(R.attendanceDetails, extra: match.first);
              },
            ),
            const SizedBox(height: 16),
            if (records.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No records for this month', style: TextStyle(color: AppColors.textSecondary))),
              )
            else
              for (final r in records) _RecordTile(record: r),
          ]);
        },
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});
  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final s = record.status;
    return InkWell(
      onTap: () => context.push(R.attendanceDetails, extra: record),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          SizedBox(width: 64, child: Text(Fmt.dateShort(record.date), style: const TextStyle(fontSize: 14))),
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: s.background, shape: BoxShape.circle),
            child: Icon(Icons.location_on, size: 16, color: s.color),
          ),
          const SizedBox(width: 18),
          Expanded(child: Text(s.label, style: TextStyle(fontSize: 14, color: s.color, fontWeight: FontWeight.w500))),
          Text(record.hoursWorked == null ? '--' : Fmt.duration(record.hoursWorked!),
              style: const TextStyle(fontSize: 14)),
        ]),
      ),
    );
  }
}
