import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../../domain/leave.dart';
import '../cubit/leave_cubit.dart';

class LeaveRequestPage extends StatefulWidget {
  const LeaveRequestPage({super.key});

  @override
  State<LeaveRequestPage> createState() => _LeaveRequestPageState();
}

class _LeaveRequestPageState extends State<LeaveRequestPage> {
  final _form = GlobalKey<FormState>();
  final _startText = TextEditingController();
  final _endText = TextEditingController();
  final _reason = TextEditingController();
  String? _type;
  DateTime? _start;
  DateTime? _end;
  bool _loading = false;

  @override
  void dispose() {
    _startText.dispose();
    _endText.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pick(bool isStart) async {
    final today = Fmt.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _start : _end) ?? _start ?? today,
      firstDate: isStart ? today : (_start ?? today),
      lastDate: today.add(const Duration(days: 730)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
        _startText.text = Fmt.dateLong(picked);
        if (_end != null && _end!.isBefore(picked)) {
          _end = null;
          _endText.clear();
        }
      } else {
        _end = picked;
        _endText.text = Fmt.dateLong(picked);
      }
    });
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final r = await context.read<LeaveCubit>().submit(
          type: _type!, start: _start!, end: _end!, reason: _reason.text.trim());
      if (!mounted) return;
      context.go(R.success,
          extra: SuccessArgs(
              message: 'Your leave request has been submitted successfully',
              nextRoute: R.leaveOf(r.id)));
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      context.push(R.error, extra: e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    const calendar = Icon(Icons.calendar_today_outlined, size: 20, color: Colors.black);
    return AppPage(
      title: 'Leave Request',
      child: Form(
        key: _form,
        child: ListView(children: [
          AppDropdown<String>(
            label: 'Leave Type', hint: 'Select leave type', items: leaveTypes,
            itemLabel: (e) => e, value: _type, onChanged: (v) => setState(() => _type = v),
            validator: (v) => v == null ? 'Select a leave type' : null,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Start Date', hint: 'Select start date', controller: _startText, readOnly: true,
            onTap: () => _pick(true), suffixIcon: calendar,
            validator: (v) => Validators.required(v, 'Start date'),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'End Date', hint: 'Select end date', controller: _endText, readOnly: true,
            onTap: () => _pick(false), suffixIcon: calendar,
            validator: (v) => Validators.required(v, 'End date'),
          ),
          const SizedBox(height: 16),
          AppTextField(label: 'Reason', hint: 'Add information (optional)', controller: _reason, maxLines: 4),
          const SizedBox(height: 28),
          PrimaryButton(label: 'Submit Request', onPressed: _submit, loading: _loading),
        ]),
      ),
    );
  }
}
