import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../../domain/attendance.dart';
import '../cubit/attendance_cubit.dart';

class ClockResultArgs {
  const ClockResultArgs({required this.isClockIn, required this.record});
  final bool isClockIn;
  final AttendanceRecord record;
}

/// Checks GPS against the workplace geofence, then clocks in or out.
class LocationVerificationPage extends StatefulWidget {
  const LocationVerificationPage({super.key, required this.isClockIn});
  final bool isClockIn;

  @override
  State<LocationVerificationPage> createState() => _LocationVerificationPageState();
}

class _LocationVerificationPageState extends State<LocationVerificationPage> {
  GeoCheck? _check;
  bool _checking = true;
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _verify();
  }

  Future<void> _verify() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final c = await sl<AttendanceRepository>().verifyLocation();
      if (mounted) setState(() => _check = c);
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _check = null;
          _error = e.message;
        });
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _continue() async {
    final check = _check;
    if (check == null) return;
    setState(() => _submitting = true);
    final cubit = context.read<AttendanceCubit>();
    try {
      final record = widget.isClockIn ? await cubit.clockIn(check) : await cubit.clockOut(check);
      if (!mounted) return;
      context.pushReplacement(R.clockResult, extra: ClockResultArgs(isClockIn: widget.isClockIn, record: record));
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      context.push(R.error, extra: e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _check;
    final ok = c?.inRange ?? false;
    return AppPage(
      title: 'Location Verification',
      child: _checking
          ? const Center(child: CircularProgressIndicator())
          : ListView(children: [
              const SizedBox(height: 32),
              Center(
                child: Container(
                  width: 146, height: 146,
                  decoration: BoxDecoration(
                      color: ok || c == null ? AppColors.skyBlue : AppColors.redSoft, shape: BoxShape.circle),
                  child: Icon(Icons.location_on, size: 90, color: ok || c == null ? AppColors.navy : AppColors.red),
                ),
              ),
              const SizedBox(height: 40),
              Text(c?.workplaceName ?? 'Workplace', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              const SizedBox(height: 20),
              Text('Distance : ${c == null || !c.located ? '--' : '${c.distanceMeters.round()}m'}'),
              const SizedBox(height: 16),
              Text('Geofence Radius : ${c?.radiusMeters.round() ?? '--'}m'),
              const SizedBox(height: 16),
              Text('GPS : ${c?.located == true ? 'Located' : 'Not available'}'),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 13)),
              ],
              if (c != null && c.offline) ...[
                const SizedBox(height: 16),
                const Text(
                  'You are offline. This will be saved on your phone and sent to the server when you are back online.',
                  style: TextStyle(color: AppColors.amber, fontSize: 13),
                ),
              ],
              if (c != null && !ok) ...[
                const SizedBox(height: 16),
                Text(
                  c.located
                      ? 'You are outside the allowed area. Move closer to ${c.workplaceName} and retry.'
                      : 'Turn on location services and allow location access, then retry.',
                  style: const TextStyle(color: AppColors.red, fontSize: 13),
                ),
              ],
              const SizedBox(height: 36),
              PrimaryButton(
                label: 'Continue', onPressed: ok ? _continue : null, loading: _submitting,
              ),
              TextButton(
                onPressed: _submitting ? null : _verify,
                child: const Text('Retry Location', style: TextStyle(color: AppColors.navy)),
              ),
            ]),
    );
  }
}
