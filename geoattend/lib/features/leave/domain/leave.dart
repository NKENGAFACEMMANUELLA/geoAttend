import 'package:geoattend/core/core.dart';

const leaveTypes = ['Annual Leave', 'Sick Leave', 'Personal Leave', 'Maternity / Paternity Leave', 'Unpaid Leave'];

class LeaveRequest {
  const LeaveRequest({
    required this.id,
    required this.employeeName,
    required this.employeeId,
    required this.department,
    required this.type,
    required this.start,
    required this.end,
    required this.submittedAt,
    this.reason = '',
    this.status = RequestStatus.pending,
    this.approver = 'John Doe',
    this.stage = 'hod',
  });

  final String id;
  final String employeeName;
  final String employeeId;
  final String department;
  final String type;
  final DateTime start;
  final DateTime end;
  final DateTime submittedAt;
  final String reason;
  final RequestStatus status;
  final String approver;

  /// Who has to act next: 'hod', 'hr' or 'done'.
  final String stage;

  factory LeaveRequest.fromJson(Map<String, dynamic> j) => LeaveRequest(
        id: j['id'] as String,
        employeeName: (j['employeeName'] as String?) ?? '',
        employeeId: (j['employeeId'] as String?) ?? '',
        department: (j['department'] as String?) ?? '',
        type: j['type'] as String,
        start: DateTime.parse(j['start'] as String),
        end: DateTime.parse(j['end'] as String),
        submittedAt: DateTime.parse(j['submittedAt'] as String).toLocal(),
        reason: (j['reason'] as String?) ?? '',
        status: RequestStatus.values.byName(j['status'] as String),
        approver: (j['approver'] as String?) ?? '',
        stage: (j['stage'] as String?) ?? 'done',
      );

  int get days => end.difference(start).inDays + 1;

  LeaveRequest copyWith({RequestStatus? status}) => LeaveRequest(
        id: id, employeeName: employeeName, employeeId: employeeId, department: department,
        type: type, start: start, end: end, submittedAt: submittedAt, reason: reason,
        status: status ?? this.status, approver: approver, stage: stage,
      );
}

class LeaveData {
  const LeaveData({this.mine = const [], this.approvals = const []});
  final List<LeaveRequest> mine; // requests I made (employee)
  final List<LeaveRequest> approvals; // requests awaiting my decision (HOD)

  LeaveRequest? find(String id) {
    for (final r in [...mine, ...approvals]) {
      if (r.id == id) return r;
    }
    return null;
  }

  List<LeaveRequest> get pendingApprovals =>
      approvals.where((r) => r.status == RequestStatus.pending).toList();
}

abstract class LeaveRepository {
  Future<List<LeaveRequest>> mine();
  Future<List<LeaveRequest>> forApproval();
  Future<LeaveRequest> submit({required String type, required DateTime start, required DateTime end, String reason = ''});
  Future<void> decide(String id, {required bool approved});
  Future<void> cancel(String id);
}
