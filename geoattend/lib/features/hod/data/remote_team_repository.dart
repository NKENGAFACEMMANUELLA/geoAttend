import 'package:geoattend/core/core.dart';

import '../../../core/network/api_client.dart';
import '../domain/team.dart';

/// Team attendance and reports. HODs are always limited to their own
/// department by the server, whatever department the app sends.
class RemoteTeamRepository implements TeamRepository {
  RemoteTeamRepository(this._api);
  final ApiClient _api;

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<TeamData> load(DateTime date, {String? department}) async {
    final data = await _api.send(() => _api.dio.get<dynamic>('/team/attendance', queryParameters: {
          'date': _ymd(date),
          if (department != null && department.isNotEmpty) 'department': department,
        })) as Map<String, dynamic>;
    final rows = [for (final r in data['rows'] as List) TeamRow.fromJson(r as Map<String, dynamic>)];
    return TeamData(rows: rows, summary: TeamSummary.fromRows(rows));
  }

  @override
  Future<AttendanceReport> generateReport({required String type, required DateTime date, String? department}) async {
    final data = await _api.send(() => _api.dio.get<dynamic>('/reports', queryParameters: {
          'type': type,
          'date': _ymd(date),
          if (department != null && department.isNotEmpty) 'department': department,
        }));
    return AttendanceReport.fromJson(data as Map<String, dynamic>);
  }
}
