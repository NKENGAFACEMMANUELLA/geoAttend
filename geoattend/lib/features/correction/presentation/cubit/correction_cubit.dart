import 'package:geoattend/shared/shared.dart';

import '../../domain/correction.dart';

class CorrectionCubit extends AsyncCubit<List<CorrectionRequest>> {
  CorrectionCubit(this._repo);
  final CorrectionRepository _repo;

  Future<void> load() => run(_repo.mine);

  Future<void> submit({
    required DateTime date, DateTime? existingClockIn,
    required DateTime requestedIn, required DateTime requestedOut, String reason = '',
  }) async {
    await _repo.submit(
        date: date, existingClockIn: existingClockIn, requestedIn: requestedIn,
        requestedOut: requestedOut, reason: reason);
    set(await _repo.mine());
  }
}

/// HOD: correction requests waiting for (or recently given) a decision.
class CorrectionApprovalsCubit extends AsyncCubit<List<CorrectionRequest>> {
  CorrectionApprovalsCubit(this._repo);
  final CorrectionRepository _repo;

  Future<void> load() => run(_repo.forApproval);

  Future<void> decide(String id, {required bool approved}) async {
    await _repo.decide(id, approved: approved);
    set(await _repo.forApproval());
  }
}
