import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:geoattend/core/core.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../../workplace/domain/workplace.dart';
import '../domain/attendance.dart';

/// Attendance on the real API, with an offline queue:
///  - the geofence is judged by the SERVER (the phone only reports coordinates);
///  - with no connection the phone checks the last known workplace itself, saves the
///    clock-in/out, shows it as "Offline", and sends it to /attendance/sync later.
class RemoteAttendanceRepository implements AttendanceRepository {
  RemoteAttendanceRepository(this._api, this._workplaces, this._location, this._session);
  final ApiClient _api;
  final WorkplaceRepository _workplaces;
  final LocationService _location;
  final SessionController _session;

  Dio get _dio => _api.dio;
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // Keys are per user so two people sharing a phone never see each other's data.
  String get _uid => _session.user?.id ?? 'anon';
  String get _kQueue => 'att_queue_$_uid';
  String get _kCache => 'att_cache_$_uid';
  String get _kIssues => 'att_issues_$_uid';
  String get _kWorkplaces => 'att_workplaces_$_uid';

  // ------------------------------------------------------------------ load

  @override
  Future<AttendanceData> load() async {
    await _syncQueue(); // best effort
    try {
      final data = await _api.send(() => _dio.get<dynamic>('/attendance/me')) as Map<String, dynamic>;
      final history = [
        for (final h in data['history'] as List) AttendanceRecord.fromJson(h as Map<String, dynamic>),
      ];
      await (await _prefs).setString(_kCache, jsonEncode([for (final r in history) r.toJson()]));
      return _withPending(AttendanceData.fromHistory(history));
    } on NoConnectionException {
      final raw = (await _prefs).getString(_kCache);
      if (raw == null && (await _readQueue()).isEmpty) rethrow;
      final cached = raw == null
          ? <AttendanceRecord>[]
          : [for (final h in jsonDecode(raw) as List) AttendanceRecord.fromJson(h as Map<String, dynamic>)];
      return _withPending(AttendanceData.fromHistory(cached));
    }
  }

  // ------------------------------------------------------------- location

  /// The employee's workplace: from the server, or the copy saved on the last successful call.
  Future<Workplace?> _myWorkplace() async {
    final prefs = await _prefs;
    List<Workplace> list;
    try {
      list = await _workplaces.list();
      await prefs.setString(_kWorkplaces, jsonEncode([for (final w in list) {...w.toJson(), 'id': w.id}]));
    } on NoConnectionException {
      final raw = prefs.getString(_kWorkplaces);
      if (raw == null) return null;
      list = [for (final w in jsonDecode(raw) as List) Workplace.fromJson(w as Map<String, dynamic>)];
    }
    if (list.isEmpty) return null;
    final name = _session.user?.workplace;
    return list.firstWhere((w) => w.name == name, orElse: () => list.first);
  }

  @override
  Future<GeoCheck> verifyLocation() async {
    final wp = await _myWorkplace();
    final target = wp == null ? null : LatLng(wp.latitude, wp.longitude);
    final fix = await _location.currentFix(mockNear: target);
    final name = wp?.name ?? _session.user?.workplace ?? '';
    if (fix == null) {
      return GeoCheck(workplaceName: name, distanceMeters: 0, radiusMeters: wp?.radius ?? 0, located: false);
    }
    try {
      final d = await _api.send(() => _dio.post<dynamic>('/attendance/verify-location', data: _body(fix))) as Map<String, dynamic>;
      return GeoCheck(
        workplaceName: d['workplaceName'] as String,
        distanceMeters: (d['distanceMeters'] as num).toDouble(),
        radiusMeters: (d['radiusMeters'] as num).toDouble(),
        located: true,
        latitude: fix.point.latitude, longitude: fix.point.longitude,
        accuracy: fix.accuracy, mocked: fix.mocked,
      );
    } on NoConnectionException {
      if (wp == null || target == null) rethrow; // never seen the workplace: cannot check offline
      return GeoCheck(
        workplaceName: wp.name,
        distanceMeters: _location.distanceMeters(fix.point, target),
        radiusMeters: wp.radius,
        located: true,
        latitude: fix.point.latitude, longitude: fix.point.longitude,
        accuracy: fix.accuracy, mocked: fix.mocked, offline: true,
      );
    }
  }

  Map<String, dynamic> _body(LocationFix fix) => {
        'latitude': fix.point.latitude,
        'longitude': fix.point.longitude,
        if (fix.accuracy != null) 'accuracy': fix.accuracy,
        if (fix.mocked) 'mocked': true,
      };

  Map<String, dynamic> _bodyOf(GeoCheck c) => {
        'latitude': c.latitude ?? 0,
        'longitude': c.longitude ?? 0,
        if (c.accuracy != null) 'accuracy': c.accuracy,
        if (c.mocked) 'mocked': true,
      };

  // ---------------------------------------------------------- clock in/out

  @override
  Future<AttendanceRecord> clockIn(GeoCheck check) async {
    if (check.offline) return _enqueue('in', check);
    try {
      final data = await _api.send(() => _dio.post<dynamic>('/attendance/clock-in', data: _bodyOf(check)));
      return AttendanceRecord.fromJson(data as Map<String, dynamic>);
    } on NoConnectionException {
      return _enqueue('in', check); // connection dropped after the check
    }
  }

  @override
  Future<AttendanceRecord> clockOut(GeoCheck check) async {
    if (check.offline) return _enqueue('out', check);
    try {
      final data = await _api.send(() => _dio.post<dynamic>('/attendance/clock-out', data: _bodyOf(check)));
      return AttendanceRecord.fromJson(data as Map<String, dynamic>);
    } on NoConnectionException {
      return _enqueue('out', check);
    }
  }

  // ------------------------------------------------------- offline queue

  Future<List<Map<String, dynamic>>> _readQueue() async {
    final raw = (await _prefs).getString(_kQueue);
    if (raw == null) return [];
    return [for (final e in jsonDecode(raw) as List) Map<String, dynamic>.from(e as Map)];
  }

  Future<void> _writeQueue(List<Map<String, dynamic>> q) async =>
      (await _prefs).setString(_kQueue, jsonEncode(q));

  Future<AttendanceRecord> _enqueue(String type, GeoCheck check) async {
    if (!check.inRange) {
      throw AppException('You are outside the allowed area for ${check.workplaceName}.');
    }
    final now = DateTime.now();
    final queue = await _readQueue();
    final current = (await _localToday())?.clockIn;
    final queuedToday = queue.where((e) => _sameDay(DateTime.parse(e['capturedAt'] as String).toLocal(), now));
    final queuedIn = queuedToday.any((e) => e['type'] == 'in');
    final queuedOut = queuedToday.any((e) => e['type'] == 'out');

    if (type == 'in' && (current != null || queuedIn)) throw AppException('You have already clocked in today.');
    if (type == 'out' && current == null && !queuedIn) throw AppException('Clock in first before clocking out.');
    if (type == 'out' && queuedOut) throw AppException('You have already clocked out today.');

    queue.add({
      'clientId': '${now.microsecondsSinceEpoch}-$type',
      'type': type,
      'capturedAt': now.toUtc().toIso8601String(),
      ..._bodyOf(check),
    });
    await _writeQueue(queue);
    return (await _localToday())!;
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// Today's record as the phone knows it (cache + queued items).
  Future<AttendanceRecord?> _localToday() async {
    final raw = (await _prefs).getString(_kCache);
    final cached = raw == null
        ? <AttendanceRecord>[]
        : [for (final h in jsonDecode(raw) as List) AttendanceRecord.fromJson(h as Map<String, dynamic>)];
    return (await _withPending(AttendanceData.fromHistory(cached))).today;
  }

  /// Adds records for queued (not yet synced) clock-ins/outs so the UI shows them straight away.
  Future<AttendanceData> _withPending(AttendanceData base) async {
    final queue = await _readQueue();
    if (queue.isEmpty) return base;

    final byDay = <String, List<Map<String, dynamic>>>{};
    for (final e in queue) {
      final t = DateTime.parse(e['capturedAt'] as String).toLocal();
      final key = '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
      byDay.putIfAbsent(key, () => []).add(e);
    }

    final history = [...base.history];
    for (final entry in byDay.entries) {
      final day = DateTime.parse(entry.key);
      DateTime? at(String type) {
        final m = entry.value.where((e) => e['type'] == type);
        return m.isEmpty ? null : DateTime.parse(m.first['capturedAt'] as String).toLocal();
      }

      final inAt = at('in');
      final outAt = at('out');
      final i = history.indexWhere((r) => _sameDay(r.date, day) && r.status != AttendanceStatus.leave);
      if (i >= 0) {
        if (outAt != null && history[i].clockOut == null) history[i] = history[i].copyWith(clockOut: outAt);
      } else if (inAt != null) {
        final limit = DateTime(day.year, day.month, day.day, AppConfig.workStartHour, AppConfig.lateGraceMinutes);
        history.add(AttendanceRecord(
          date: day,
          status: inAt.isAfter(limit) ? AttendanceStatus.late : AttendanceStatus.present,
          clockIn: inAt, clockOut: outAt,
          workplace: _session.user?.workplace ?? '', source: 'Offline',
        ));
      }
    }
    history.sort((a, b) => b.date.compareTo(a.date));
    return AttendanceData.fromHistory(history);
  }

  Future<void> _syncQueue() async {
    final queue = await _readQueue();
    if (queue.isEmpty) return;
    try {
      final data = await _api.send(() => _dio.post<dynamic>('/attendance/sync', data: {'records': queue})) as Map<String, dynamic>;
      final rejected = [
        for (final r in data['results'] as List)
          if ((r as Map)['status'] == 'rejected') (r['message'] as String?) ?? 'A saved clock-in could not be accepted.',
      ];
      await _writeQueue([]); // accepted or refused: either way it is done
      if (rejected.isNotEmpty) {
        final prefs = await _prefs;
        final old = prefs.getStringList(_kIssues) ?? [];
        await prefs.setStringList(_kIssues, [...old, ...rejected]);
      }
    } on AppException {
      // Still offline or the server is asleep: keep the queue and try again next time.
    }
  }

  @override
  Future<List<String>> takeSyncIssues() async {
    final prefs = await _prefs;
    final issues = prefs.getStringList(_kIssues) ?? const [];
    if (issues.isNotEmpty) await prefs.remove(_kIssues);
    return issues;
  }
}
