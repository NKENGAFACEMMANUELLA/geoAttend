import 'package:flutter/material.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../../domain/attendance.dart';

class AttendanceDetailsPage extends StatelessWidget {
  const AttendanceDetailsPage({super.key, required this.record});
  final AttendanceRecord record;

  Widget _line(String label, String value, {bool big = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Text(value, style: TextStyle(fontSize: big ? 18 : 15, fontWeight: big ? FontWeight.w500 : FontWeight.w600)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final s = record.status;
    return AppPage(
      title: 'Attendance Details',
      child: Stack(children: [
        Positioned(
          right: -90, bottom: -90,
          child: Container(
            width: 260, height: 260,
            decoration: const BoxDecoration(color: AppColors.skyBlue, shape: BoxShape.circle),
          ),
        ),
        ListView(children: [
          Text(Fmt.dateLong(record.date), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 6, 18, 6),
              decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const CircleAvatar(radius: 14, backgroundColor: Colors.white24, child: Icon(Icons.check, size: 16, color: Colors.white)),
                const SizedBox(width: 10),
                Text(s.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Clock In', style: TextStyle(fontSize: 15)),
              const SizedBox(height: 4),
              Text(Fmt.time(record.clockIn), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('Clock Out', style: TextStyle(fontSize: 15)),
              const SizedBox(height: 4),
              Text(Fmt.time(record.clockOut), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ]),
          ]),
          const SizedBox(height: 12),
          _line('Hours Worked', record.hoursWorked == null ? '--' : Fmt.duration(record.hoursWorked!)),
          _line('Lateness', '${record.latenessMinutes}m'),
          const SizedBox(height: 8),
          _line('Workplace', record.workplace, big: true),
          const SizedBox(height: 8),
          Row(children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: record.locationVerified ? AppColors.greenSoft : AppColors.redSoft,
              child: Icon(Icons.location_on, size: 16,
                  color: record.locationVerified ? AppColors.green : AppColors.red),
            ),
            const SizedBox(width: 12),
            Text(record.locationVerified ? 'Location Verified' : 'Location not verified',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 8),
          _line('Record Source', record.source),
        ]),
      ]),
    );
  }
}
