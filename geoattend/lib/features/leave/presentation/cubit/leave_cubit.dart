import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../../domain/leave.dart';

class LeaveCubit extends AsyncCubit<LeaveData> {
  LeaveCubit(this._repo);
  final LeaveRepository _repo;
  UserRole _role = UserRole.employee;

  Future<LeaveData> _fetch() async => LeaveData(
        mine: _role == UserRole.employee ? await _repo.mine() : const [],
        approvals: _role != UserRole.employee ? await _repo.forApproval() : const [],
      );

  Future<void> load([UserRole? role]) {
    _role = role ?? _role;
    return run(_fetch);
  }

  Future<LeaveRequest> submit({required String type, required DateTime start, required DateTime end, String reason = ''}) async {
    final r = await _repo.submit(type: type, start: start, end: end, reason: reason);
    set(await _fetch());
    return r;
  }

  Future<void> decide(String id, {required bool approved}) async {
    await _repo.decide(id, approved: approved);
    set(await _fetch());
  }

  Future<void> cancel(String id) async {
    await _repo.cancel(id);
    set(await _fetch());
  }
}
