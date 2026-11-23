import 'package:geoattend/core/core.dart';

import '../../../core/network/api_client.dart';
import '../domain/leave.dart';

class RemoteLeaveRepository implements LeaveRepository {
  RemoteLeaveRepository(this._api);
  final ApiClient _api;

  List<LeaveRequest> _list(dynamic data) =>
      [for (final e in data as List) LeaveRequest.fromJson(e as Map<String, dynamic>)];

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<List<LeaveRequest>> mine() async => _list(await _api.send(() => _api.dio.get<dynamic>('/leave/mine')));

  @override
  Future<List<LeaveRequest>> forApproval() async => _list(await _api.send(() => _api.dio.get<dynamic>('/leave/pending')));

  @override
  Future<LeaveRequest> submit({required String type, required DateTime start, required DateTime end, String reason = ''}) async {
    final data = await _api.send(() => _api.dio.post<dynamic>('/leave', data: {
          'type': type, 'start': _ymd(start), 'end': _ymd(end), 'reason': reason,
        }));
    return LeaveRequest.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<void> decide(String id, {required bool approved}) async {
    await _api.send(() => _api.dio.patch<dynamic>('/leave/$id/decision', data: {'approved': approved}));
  }

  @override
  Future<void> cancel(String id) async {
    await _api.send(() => _api.dio.delete<dynamic>('/leave/$id'));
  }
}
