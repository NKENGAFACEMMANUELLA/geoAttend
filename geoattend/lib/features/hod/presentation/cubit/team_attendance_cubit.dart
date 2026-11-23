import 'package:geoattend/shared/shared.dart';

import '../../domain/team.dart';

class TeamAttendanceCubit extends AsyncCubit<TeamData> {
  TeamAttendanceCubit(this._repo);
  final TeamRepository _repo;

  Future<void> load(DateTime date, {String? department}) =>
      run(() => _repo.load(date, department: department));
}
