import 'package:geoattend/core/core.dart';
import 'package:intl/intl.dart';

import '../domain/team.dart';

class MockTeamRepository implements TeamRepository {
  static const _people = [
    ('Sarah Kim', 'EMP024', 'Senior Analyst', 'Sales'),
    ('David Lee', 'EMP031', 'Junior Analyst', 'Sales'),
    ('Michael Brown', 'EMP045', 'Analyst', 'Sales'),
    ('Emily Davis', 'EMP052', 'Sales Executive', 'Sales'),
    ('James Taylor', 'EMP060', 'Sales Executive', 'Sales'),
    ('Akwi Joy', 'EMP018', 'Marketing Officer', 'Marketing'),
    ('Atabong Joel', 'EMP001', 'Software Engineer', 'Marketing'),
    ('John Doe', 'EMP007', 'Software Engineer', 'IT'),
    ('Alice Besingi', 'EMP066', 'Accountant', 'Finance'),
    ('Amboh Queency', 'EMP071', 'Support Agent', 'Customer Service'),
  ];

  static const _cycle = [
    AttendanceStatus.present, AttendanceStatus.present, AttendanceStatus.present,
    AttendanceStatus.late, AttendanceStatus.present, AttendanceStatus.absent,
    AttendanceStatus.present, AttendanceStatus.leave,
  ];

  AttendanceStatus _status(int i, DateTime date) => _cycle[(i + date.day) % _cycle.length];

  TeamData _dataFor(DateTime date, String? department) {
    final rows = <TeamRow>[];
    for (var i = 0; i < _people.length; i++) {
      final p = _people[i];
      if (department != null && p.$4 != department) continue;
      final status = _status(i, date);
      final time = switch (status) {
        AttendanceStatus.present => Fmt.atTime(date, 7, 50 + (i * 3) % 14),
        AttendanceStatus.late => Fmt.atTime(date, 8, 20 + (i * 4) % 30),
        _ => null,
      };
      rows.add(TeamRow(name: p.$1, employeeId: p.$2, position: p.$3, department: p.$4, status: status, time: time));
    }
    return TeamData(rows: rows, summary: TeamSummary.fromRows(rows));
  }

  @override
  Future<TeamData> load(DateTime date, {String? department}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _dataFor(date, department);
  }

  List<DateTime> _workdays(DateTime from, DateTime to) {
    final out = <DateTime>[];
    for (var d = Fmt.dateOnly(from); !d.isAfter(to); d = DateTime(d.year, d.month, d.day + 1)) {
      if (d.weekday <= DateTime.friday) out.add(d);
    }
    return out;
  }

  @override
  Future<AttendanceReport> generateReport({required String type, required DateTime date, String? department}) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final today = Fmt.dateOnly(DateTime.now());
    final day = Fmt.dateOnly(date).isAfter(today) ? today : Fmt.dateOnly(date);
    final scope = department ?? 'All departments';
    final short = DateFormat('EEE d MMM');
    final now = DateTime.now();

    if (type == 'Present/Late/Absent Summary') {
      final s = _dataFor(day, department).summary;
      String share(int n) => '${s.percentOf(n)}%';
      return AttendanceReport(
        title: type, period: Fmt.dateLong(day), scope: scope, generatedAt: now,
        highlights: [
          ReportStat('Attendance rate', '${s.rate}%'),
          ReportStat('Present', '${s.present}'),
          ReportStat('Absent', '${s.absent}'),
        ],
        columns: const ['Status', 'Employees', 'Share'],
        rows: [
          ['Present', '${s.present}', share(s.present)],
          ['Late', '${s.late}', share(s.late)],
          ['Absent', '${s.absent}', share(s.absent)],
          ['On Leave', '${s.onLeave}', share(s.onLeave)],
          ['Total', '${s.total}', '100%'],
        ],
      );
    }

    final isWeekly = type == 'Weekly Attendance';
    final monday = DateTime(day.year, day.month, day.day - (day.weekday - 1));
    final friday = DateTime(monday.year, monday.month, monday.day + 4);
    final from = isWeekly ? monday : DateTime(day.year, day.month, 1);
    final to = isWeekly ? (friday.isAfter(today) ? today : friday) : day;
    final days = _workdays(from, to);
    if (days.isEmpty) throw AppException('There are no working days in this period.');

    final period = isWeekly
        ? '${short.format(monday)} - ${short.format(friday)} ${friday.year}'
        : '${DateFormat('MMMM yyyy').format(day)} (to ${short.format(to)})';

    if (type == 'Attendance by Employee') {
      final people = [
        for (var i = 0; i < _people.length; i++)
          if (department == null || _people[i].$4 == department) i,
      ];
      final rows = <List<String>>[];
      var rateSum = 0;
      for (final i in people) {
        int count(AttendanceStatus s) => days.where((d) => _status(i, d) == s).length;
        final present = count(AttendanceStatus.present), late = count(AttendanceStatus.late);
        final rate = ((present + late) / days.length * 100).round();
        rateSum += rate;
        rows.add([
          _people[i].$1, _people[i].$2, '$present', '$late',
          '${count(AttendanceStatus.absent)}', '${count(AttendanceStatus.leave)}', '$rate%',
        ]);
      }
      return AttendanceReport(
        title: type, period: period, scope: scope, generatedAt: now,
        highlights: [
          ReportStat('Employees', '${people.length}'),
          ReportStat('Avg. attendance', people.isEmpty ? '0%' : '${(rateSum / people.length).round()}%'),
          ReportStat('Days covered', '${days.length}'),
        ],
        columns: const ['Employee', 'ID', 'Present', 'Late', 'Absent', 'On Leave', 'Rate'],
        rows: rows,
      );
    }

    // Weekly / Monthly: one row per working day.
    final rows = <List<String>>[];
    var rateSum = 0, lateTotal = 0, absentTotal = 0;
    for (final d in days) {
      final s = _dataFor(d, department).summary;
      rateSum += s.rate;
      lateTotal += s.late;
      absentTotal += s.absent;
      rows.add([short.format(d), '${s.present}', '${s.late}', '${s.absent}', '${s.onLeave}', '${s.rate}%']);
    }
    return AttendanceReport(
      title: type, period: period, scope: scope, generatedAt: now,
      highlights: [
        ReportStat('Avg. attendance', '${(rateSum / days.length).round()}%'),
        ReportStat('Late arrivals', '$lateTotal'),
        ReportStat('Absences', '$absentTotal'),
      ],
      columns: const ['Date', 'Present', 'Late', 'Absent', 'On Leave', 'Rate'],
      rows: rows,
    );
  }
}
