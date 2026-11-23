import 'package:geoattend/shared/shared.dart';

import '../../domain/attendance.dart';

class AttendanceCubit extends AsyncCubit<AttendanceData> {
  AttendanceCubit(this._repo);
  final AttendanceRepository _repo;

  Future<void> load() => run(_repo.load);

  Future<AttendanceRecord> clockIn(GeoCheck check) async {
    final r = await _repo.clockIn(check);
    set(await _repo.load());
    return r;
  }

  Future<AttendanceRecord> clockOut(GeoCheck check) async {
    final r = await _repo.clockOut(check);
    set(await _repo.load());
    return r;
  }
}
