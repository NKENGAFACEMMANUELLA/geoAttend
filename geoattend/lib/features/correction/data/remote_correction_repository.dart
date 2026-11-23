import 'package:geoattend/core/core.dart';

import '../../../core/network/api_client.dart';
import '../domain/correction.dart';

class RemoteCorrectionRepository implements CorrectionRepository {
  RemoteCorrectionRepository(this._api);
  final ApiClient _api;

  List<CorrectionRequest> _list(dynamic data) =>
      [for (final e in data as List) CorrectionRequest.fromJson(e as Map<String, dynamic>)];

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<List<CorrectionRequest>> mine() async => _list(await _api.send(() => _api.dio.get<dynamic>('/corrections/mine')));

  @override
  Future<List<CorrectionRequest>> forApproval() async =>
      _list(await _api.send(() => _api.dio.get<dynamic>('/corrections/pending')));

  @override
  Future<CorrectionRequest> submit({
    required DateTime date, DateTime? existingClockIn,
    required DateTime requestedIn, required DateTime requestedOut, String reason = '',
  }) async {
    final data = await _api.send(() => _api.dio.post<dynamic>('/corrections', data: {
          'date': _ymd(date),
          // Always send UTC instants so the server and phone agree on the time.
          'requestedClockIn': requestedIn.toUtc().toIso8601String(),
          'requestedClockOut': requestedOut.toUtc().toIso8601String(),
          'reason': reason,
        }));
    return CorrectionRequest.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<void> decide(String id, {required bool approved}) async {
    await _api.send(() => _api.dio.patch<dynamic>('/corrections/$id/decision', data: {'approved': approved}));
  }
}
