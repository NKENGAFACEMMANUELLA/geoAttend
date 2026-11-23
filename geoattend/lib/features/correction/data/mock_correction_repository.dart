import 'package:geoattend/core/core.dart';

import '../domain/correction.dart';

class MockCorrectionRepository implements CorrectionRepository {
  late final List<CorrectionRequest> _items = [
    CorrectionRequest(
      id: 'c1',
      date: Fmt.dateOnly(DateTime.now()).subtract(const Duration(days: 6)),
      existingClockIn: Fmt.atTime(DateTime.now().subtract(const Duration(days: 6)), 8, 25),
      requestedClockIn: Fmt.atTime(DateTime.now().subtract(const Duration(days: 6)), 7, 58),
      requestedClockOut: Fmt.atTime(DateTime.now().subtract(const Duration(days: 6)), 17, 2),
      reason: 'System error', status: RequestStatus.rejected,
    ),
  ];

  @override
  Future<List<CorrectionRequest>> mine() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List.of(_items.reversed);
  }

  @override
  Future<List<CorrectionRequest>> forApproval() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final d = Fmt.dateOnly(DateTime.now()).subtract(const Duration(days: 1));
    return [
      CorrectionRequest(
        id: 'ca1', date: d, existingClockIn: Fmt.atTime(d, 8, 25),
        requestedClockIn: Fmt.atTime(d, 7, 45), requestedClockOut: Fmt.atTime(d, 17, 0),
        reason: 'System error', employeeName: 'Sarah Kim', employeeId: 'EMP024',
      ),
    ];
  }

  @override
  Future<void> decide(String id, {required bool approved}) =>
      Future<void>.delayed(const Duration(milliseconds: 300));

  @override
  Future<CorrectionRequest> submit({
    required DateTime date, DateTime? existingClockIn,
    required DateTime requestedIn, required DateTime requestedOut, String reason = '',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final r = CorrectionRequest(
      id: 'c${DateTime.now().microsecondsSinceEpoch}', date: date, existingClockIn: existingClockIn,
      requestedClockIn: requestedIn, requestedClockOut: requestedOut, reason: reason,
    );
    _items.add(r);
    return r;
  }
}
