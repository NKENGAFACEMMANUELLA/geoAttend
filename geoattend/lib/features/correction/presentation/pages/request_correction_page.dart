import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../../../attendance/domain/attendance.dart';
import '../../../attendance/presentation/cubit/attendance_cubit.dart';
import '../cubit/correction_cubit.dart';

class RequestCorrectionPage extends StatefulWidget {
  const RequestCorrectionPage({super.key});

  @override
  State<RequestCorrectionPage> createState() => _RequestCorrectionPageState();
}

class _RequestCorrectionPageState extends State<RequestCorrectionPage> {
  final _form = GlobalKey<FormState>();
  final _existing = TextEditingController();
  final _inText = TextEditingController();
  final _outText = TextEditingController();
  final _reason = TextEditingController();
  AttendanceRecord? _record;
  TimeOfDay? _in;
  TimeOfDay? _out;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_existing, _inText, _outText, _reason]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickTime(bool isIn) async {
    final t = await showTimePicker(
      context: context,
      initialTime: (isIn ? _in : _out) ?? TimeOfDay(hour: isIn ? 8 : 17, minute: 0),
    );
    if (t == null || !mounted) return;
    setState(() {
      if (isIn) {
        _in = t;
        _inText.text = t.format(context);
      } else {
        _out = t;
        _outText.text = t.format(context);
      }
    });
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final r = _record!;
    final reqIn = Fmt.atTime(r.date, _in!.hour, _in!.minute);
    final reqOut = Fmt.atTime(r.date, _out!.hour, _out!.minute);
    if (!reqOut.isAfter(reqIn)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clock-out must be after clock-in.')));
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<CorrectionCubit>().submit(
          date: r.date, existingClockIn: r.clockIn, requestedIn: reqIn, requestedOut: reqOut, reason: _reason.text.trim());
      if (!mounted) return;
      context.go(R.success,
          extra: const SuccessArgs(
              message: 'Your correction request has been submitted successfully',
              nextRoute: R.correctionList));
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      context.push(R.error, extra: e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = (context.watch<AttendanceCubit>().state.data?.history ?? const <AttendanceRecord>[])
        .where((r) => r.clockIn != null)
        .take(30)
        .toList();
    const chevron = Icon(Icons.chevron_right, color: Colors.black);
    return AppPage(
      title: 'Request Correction',
      actions: [
        IconButton(
          tooltip: 'My correction requests',
          icon: const Icon(Icons.history),
          onPressed: () => context.push(R.correctionList),
        ),
      ],
      child: Form(
        key: _form,
        child: ListView(children: [
          AppDropdown<AttendanceRecord>(
            label: 'Attendance Date', hint: 'Select a day', items: history,
            itemLabel: (r) => Fmt.dateLong(r.date), value: _record,
            validator: (v) => v == null ? 'Select the attendance date' : null,
            onChanged: (r) => setState(() {
              _record = r;
              _existing.text = Fmt.time(r?.clockIn);
            }),
          ),
          const SizedBox(height: 16),
          AppTextField(label: 'Existing Clock-In', hint: '--', controller: _existing, readOnly: true),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Requested Clock-In', hint: 'Select time', controller: _inText, readOnly: true,
            onTap: () => _pickTime(true), suffixIcon: chevron,
            validator: (v) => Validators.required(v, 'Requested clock-in'),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Requested Clock-Out', hint: 'Select time', controller: _outText, readOnly: true,
            onTap: () => _pickTime(false), suffixIcon: chevron,
            validator: (v) => Validators.required(v, 'Requested clock-out'),
          ),
          const SizedBox(height: 16),
          AppTextField(label: 'Reason', hint: 'System error (optional)', controller: _reason, maxLines: 3),
          const SizedBox(height: 28),
          PrimaryButton(label: 'Submit Request', onPressed: _submit, loading: _loading),
        ]),
      ),
    );
  }
}
