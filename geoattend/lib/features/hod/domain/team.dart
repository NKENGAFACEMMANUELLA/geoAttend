import 'package:geoattend/core/core.dart';

const reportTypes = [
  'Weekly Attendance',
  'Monthly Attendance',
  'Attendance by Employee',
  'Present/Late/Absent Summary',
];

class TeamRow {
  const TeamRow({
    required this.name,
    required this.employeeId,
    required this.position,
    required this.department,
    required this.status,
    this.time,
  });
  final String name;
  final String employeeId;
  final String position;
  final String department;
  final AttendanceStatus status;
  final DateTime? time; // clock-in time

  factory TeamRow.fromJson(Map<String, dynamic> j) => TeamRow(
        name: j['name'] as String,
        employeeId: (j['employeeId'] as String?) ?? '',
        position: (j['position'] as String?) ?? '',
        department: (j['department'] as String?) ?? '',
        status: AttendanceStatus.values.byName(j['status'] as String),
        time: j['time'] == null ? null : DateTime.parse(j['time'] as String).toLocal(),
      );
}

class TeamSummary {
  const TeamSummary({required this.present, required this.late, required this.absent, required this.onLeave});
  final int present;
  final int late;
  final int absent;
  final int onLeave;

  int get total => present + late + absent + onLeave;
  int percentOf(int n) => total == 0 ? 0 : (n / total * 100).round();
  int get rate => percentOf(present + late);

  factory TeamSummary.fromRows(List<TeamRow> rows) {
    int c(AttendanceStatus s) => rows.where((r) => r.status == s).length;
    return TeamSummary(
      present: c(AttendanceStatus.present), late: c(AttendanceStatus.late),
      absent: c(AttendanceStatus.absent), onLeave: c(AttendanceStatus.leave),
    );
  }
}

class TeamData {
  const TeamData({required this.rows, required this.summary});
  final List<TeamRow> rows;
  final TeamSummary summary;
}

class ReportStat {
  const ReportStat(this.label, this.value);
  final String label;
  final String value;
}

/// A generated attendance report: highlights + a table.
class AttendanceReport {
  const AttendanceReport({
    required this.title,
    required this.period,
    required this.scope,
    required this.generatedAt,
    required this.highlights,
    required this.columns,
    required this.rows,
  });
  final String title;
  final String period;
  final String scope;
  final DateTime generatedAt;
  final List<ReportStat> highlights;
  final List<String> columns;
  final List<List<String>> rows;

  factory AttendanceReport.fromJson(Map<String, dynamic> j) => AttendanceReport(
        title: j['title'] as String,
        period: j['period'] as String,
        scope: j['scope'] as String,
        generatedAt: DateTime.parse(j['generatedAt'] as String).toLocal(),
        highlights: [
          for (final h in j['highlights'] as List)
            ReportStat((h as Map)['label'] as String, h['value'] as String),
        ],
        columns: [for (final c in j['columns'] as List) c as String],
        rows: [
          for (final r in j['rows'] as List) [for (final cell in r as List) cell as String],
        ],
      );

  String toCsv() {
    String esc(String v) => '"${v.replaceAll('"', '""')}"';
    final b = StringBuffer()..writeln(columns.map(esc).join(','));
    for (final r in rows) {
      b.writeln(r.map(esc).join(','));
    }
    return b.toString();
  }
}

abstract class TeamRepository {
  /// Attendance of every employee on [date]; filtered to [department] when given.
  Future<TeamData> load(DateTime date, {String? department});
  Future<AttendanceReport> generateReport({required String type, required DateTime date, String? department});
}
