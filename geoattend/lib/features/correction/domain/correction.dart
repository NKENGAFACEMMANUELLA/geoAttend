import 'package:geoattend/core/core.dart';

class CorrectionRequest {
  const CorrectionRequest({
    required this.id,
    required this.date,
    required this.requestedClockIn,
    required this.requestedClockOut,
    this.existingClockIn,
    this.reason = '',
    this.status = RequestStatus.pending,
    this.employeeName = '',
    this.employeeId = '',
  });

  final String id;
  final DateTime date;
  final DateTime? existingClockIn;
  final DateTime requestedClockIn;
  final DateTime requestedClockOut;
  final String reason;
  final RequestStatus status;
  final String employeeName; // shown to the HOD
  final String employeeId;

  factory CorrectionRequest.fromJson(Map<String, dynamic> j) => CorrectionRequest(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        existingClockIn: j['existingClockIn'] == null ? null : DateTime.parse(j['existingClockIn'] as String).toLocal(),
        requestedClockIn: DateTime.parse(j['requestedClockIn'] as String).toLocal(),
        requestedClockOut: DateTime.parse(j['requestedClockOut'] as String).toLocal(),
        reason: (j['reason'] as String?) ?? '',
        status: RequestStatus.values.byName(j['status'] as String),
        employeeName: (j['employeeName'] as String?) ?? '',
        employeeId: (j['employeeId'] as String?) ?? '',
      );
}

abstract class CorrectionRepository {
  Future<List<CorrectionRequest>> mine();
  Future<CorrectionRequest> submit({
    required DateTime date,
    DateTime? existingClockIn,
    required DateTime requestedIn,
    required DateTime requestedOut,
    String reason = '',
  });

  /// HOD: correction requests from their department.
  Future<List<CorrectionRequest>> forApproval();
  Future<void> decide(String id, {required bool approved});
}
