import 'package:geoattend/core/core.dart';

class AttendanceRecord {
  const AttendanceRecord({
    required this.date,
    required this.status,
    this.clockIn,
    this.clockOut,
    this.workplace = 'Main Office',
    this.locationVerified = true,
    this.source = 'Online',
  });

  final DateTime date;
  final AttendanceStatus status;
  final DateTime? clockIn;
  final DateTime? clockOut;
  final String workplace;
  final bool locationVerified;
  final String source;

  Duration? get hoursWorked =>
      (clockIn != null && clockOut != null) ? clockOut!.difference(clockIn!) : null;

  int get latenessMinutes {
    if (status != AttendanceStatus.late || clockIn == null) return 0;
    final m = clockIn!.difference(Fmt.atTime(date, AppConfig.workStartHour, 0)).inMinutes;
    return m < 0 ? 0 : m;
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) => AttendanceRecord(
        date: DateTime.parse(j['date'] as String), // "YYYY-MM-DD" = local midnight
        status: AttendanceStatus.values.byName(j['status'] as String),
        clockIn: _time(j['clockIn']),
        clockOut: _time(j['clockOut']),
        workplace: (j['workplace'] as String?) ?? '',
        locationVerified: (j['locationVerified'] as bool?) ?? true,
        source: (j['source'] as String?) ?? 'Online',
      );

  static DateTime? _time(dynamic v) => v == null ? null : DateTime.parse(v as String).toLocal();

  Map<String, dynamic> toJson() => {
        'date': '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'status': status.name,
        'clockIn': clockIn?.toUtc().toIso8601String(),
        'clockOut': clockOut?.toUtc().toIso8601String(),
        'workplace': workplace,
        'locationVerified': locationVerified,
        'source': source,
      };

  AttendanceRecord copyWith({DateTime? clockOut}) => AttendanceRecord(
        date: date,
        status: status,
        clockIn: clockIn,
        clockOut: clockOut ?? this.clockOut,
        workplace: workplace,
        locationVerified: locationVerified,
        source: source,
      );
}

class AttendanceData {
  const AttendanceData({this.today, this.history = const []});
  final AttendanceRecord? today;
  final List<AttendanceRecord> history; // newest first, includes today
  /// Builds the data from a newest-first history; "today" is the record of today's date with a clock-in.
  factory AttendanceData.fromHistory(List<AttendanceRecord> history) {
    final now = DateTime.now();
    AttendanceRecord? today;
    for (final r in history) {
      if (r.date.year == now.year && r.date.month == now.month && r.date.day == now.day && r.clockIn != null) {
        today = r;
        break;
      }
    }
    return AttendanceData(today: today, history: history);
  }

  bool get hasClockedIn => today?.clockIn != null;
  bool get hasClockedOut => today?.clockOut != null;
}

/// Result of the GPS + geofence check shown on "Location Verification".
class GeoCheck {
  const GeoCheck({
    required this.workplaceName,
    required this.distanceMeters,
    required this.radiusMeters,
    required this.located,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.mocked = false,
    this.offline = false,
  });
  final String workplaceName;
  final double distanceMeters;
  final double radiusMeters;
  final bool located;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final bool mocked;

  /// True when the check was done on the phone because there was no connection.
  final bool offline;
  bool get inRange => located && distanceMeters <= radiusMeters;
}

abstract class AttendanceRepository {
  Future<AttendanceData> load();
  Future<GeoCheck> verifyLocation();
  Future<AttendanceRecord> clockIn(GeoCheck check);
  Future<AttendanceRecord> clockOut(GeoCheck check);

  /// Messages about offline records the server refused when syncing (cleared once read).
  Future<List<String>> takeSyncIssues();
}
