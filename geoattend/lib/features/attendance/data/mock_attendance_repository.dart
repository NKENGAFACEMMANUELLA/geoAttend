import 'package:geoattend/core/core.dart';
import 'package:latlong2/latlong.dart';

import '../../workplace/domain/workplace.dart';
import '../domain/attendance.dart';

class MockAttendanceRepository implements AttendanceRepository {
  MockAttendanceRepository(this._workplaces, this._location, this._session);
  final WorkplaceRepository _workplaces;
  final LocationService _location;
  final SessionController _session;

  late final List<AttendanceRecord> _past = _seed();
  AttendanceRecord? _today;

  List<AttendanceRecord> _seed() {
    final today = Fmt.dateOnly(DateTime.now());
    const pattern = [
      AttendanceStatus.present, AttendanceStatus.late, AttendanceStatus.present,
      AttendanceStatus.absent, AttendanceStatus.present, AttendanceStatus.leave,
      AttendanceStatus.present, AttendanceStatus.present,
    ];
    final out = <AttendanceRecord>[];
    for (var i = 1; i <= 40; i++) {
      final day = today.subtract(Duration(days: i));
      if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) continue;
      final s = pattern[i % pattern.length];
      switch (s) {
        case AttendanceStatus.present:
          out.add(AttendanceRecord(date: day, status: s,
              clockIn: Fmt.atTime(day, 7, 55 + i % 10), clockOut: Fmt.atTime(day, 17, i % 6)));
        case AttendanceStatus.late:
          out.add(AttendanceRecord(date: day, status: s,
              clockIn: Fmt.atTime(day, 8, 20 + i % 25), clockOut: Fmt.atTime(day, 17, 5)));
        case AttendanceStatus.absent:
        case AttendanceStatus.leave:
          out.add(AttendanceRecord(date: day, status: s, locationVerified: false));
      }
    }
    return out;
  }

  @override
  Future<AttendanceData> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return AttendanceData(
      today: _today,
      history: [if (_today != null) _today!, ..._past],
    );
  }

  Future<Workplace> _myWorkplace() async {
    final all = await _workplaces.list();
    final name = _session.user?.workplace ?? 'Main Office';
    return all.firstWhere((w) => w.name == name, orElse: () => all.first);
  }

  @override
  Future<GeoCheck> verifyLocation() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final wp = await _myWorkplace();
    final target = LatLng(wp.latitude, wp.longitude);
    final pos = await _location.currentPosition(mockNear: target);
    if (pos == null) {
      return GeoCheck(workplaceName: wp.name, distanceMeters: 0, radiusMeters: wp.radius, located: false);
    }
    return GeoCheck(
      workplaceName: wp.name,
      distanceMeters: _location.distanceMeters(pos, target),
      radiusMeters: wp.radius,
      located: true,
    );
  }

  @override
  Future<AttendanceRecord> clockIn(GeoCheck check) async {
    if (!check.inRange) throw AppException('You are outside the allowed area for ${check.workplaceName}.');
    if (_today?.clockIn != null) throw AppException('You have already clocked in today.');
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final now = DateTime.now();
    final limit = Fmt.atTime(now, AppConfig.workStartHour, AppConfig.lateGraceMinutes);
    _today = AttendanceRecord(
      date: Fmt.dateOnly(now),
      status: now.isAfter(limit) ? AttendanceStatus.late : AttendanceStatus.present,
      clockIn: now,
      workplace: check.workplaceName,
    );
    return _today!;
  }

  @override
  Future<List<String>> takeSyncIssues() async => const [];

  @override
  Future<AttendanceRecord> clockOut(GeoCheck check) async {
    if (!check.inRange) throw AppException('You are outside the allowed area for ${check.workplaceName}.');
    final t = _today;
    if (t == null || t.clockIn == null) throw AppException('Clock in first before clocking out.');
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _today = t.copyWith(clockOut: DateTime.now());
    return _today!;
  }
}
