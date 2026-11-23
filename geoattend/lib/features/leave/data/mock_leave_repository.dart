import 'package:geoattend/core/core.dart';

import '../domain/leave.dart';

class MockLeaveRepository implements LeaveRepository {
  MockLeaveRepository(this._session);
  final SessionController _session;

  late final List<LeaveRequest> _mine = [
    LeaveRequest(
      id: 'l0', employeeName: 'Emmanuella Atefaec', employeeId: 'EMP0013', department: 'IT',
      type: 'Sick Leave', start: DateTime.now().subtract(const Duration(days: 20)),
      end: DateTime.now().subtract(const Duration(days: 19)),
      submittedAt: DateTime.now().subtract(const Duration(days: 22)),
      reason: 'Medical appointment', status: RequestStatus.approved,
    ),
  ];

  late final List<LeaveRequest> _approvals = [
    LeaveRequest(
      id: 'a1', employeeName: 'Sarah Kim', employeeId: 'EMP00124', department: 'Sales',
      type: 'Annual Leave', start: DateTime.now().add(const Duration(days: 2)),
      end: DateTime.now().add(const Duration(days: 4)),
      submittedAt: DateTime.now().subtract(const Duration(hours: 5)), reason: 'Personal reasons',
    ),
    LeaveRequest(
      id: 'a2', employeeName: 'David Lee', employeeId: 'EMP031', department: 'Sales',
      type: 'Sick Leave', start: DateTime.now().add(const Duration(days: 1)),
      end: DateTime.now().add(const Duration(days: 1)),
      submittedAt: DateTime.now().subtract(const Duration(hours: 2)), reason: 'Not feeling well',
    ),
  ];

  Future<void> _wait() => Future<void>.delayed(const Duration(milliseconds: 400));

  @override
  Future<List<LeaveRequest>> mine() async {
    await _wait();
    return List.of(_mine.reversed);
  }

  @override
  Future<List<LeaveRequest>> forApproval() async {
    await _wait();
    return List.of(_approvals);
  }

  @override
  Future<LeaveRequest> submit({required String type, required DateTime start, required DateTime end, String reason = ''}) async {
    await _wait();
    final u = _session.user;
    final r = LeaveRequest(
      id: 'l${DateTime.now().microsecondsSinceEpoch}',
      employeeName: u?.name ?? '', employeeId: u?.employeeId ?? '', department: u?.department ?? '',
      type: type, start: start, end: end, submittedAt: DateTime.now(), reason: reason,
    );
    _mine.add(r);
    return r;
  }

  void _replace(List<LeaveRequest> list, String id, RequestStatus s) {
    final i = list.indexWhere((e) => e.id == id);
    if (i >= 0) list[i] = list[i].copyWith(status: s);
  }

  @override
  Future<void> decide(String id, {required bool approved}) async {
    await _wait();
    _replace(_approvals, id, approved ? RequestStatus.approved : RequestStatus.rejected);
  }

  @override
  Future<void> cancel(String id) async {
    await _wait();
    _mine.removeWhere((e) => e.id == id);
  }
}
