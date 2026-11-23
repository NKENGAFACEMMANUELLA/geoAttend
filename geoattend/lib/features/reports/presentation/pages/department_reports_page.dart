import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../../../admin/domain/admin.dart';
import '../../../admin/presentation/cubit/admin_cubits.dart';
import '../../../hod/domain/team.dart';

/// HOD and Admin "Reports" tab: choose a report, then view and export it.
class DepartmentReportsPage extends StatefulWidget {
  const DepartmentReportsPage({super.key});

  @override
  State<DepartmentReportsPage> createState() => _DepartmentReportsPageState();
}

class _DepartmentReportsPageState extends State<DepartmentReportsPage> {
  static const _allDepartments = 'All departments';
  final _form = GlobalKey<FormState>();
  String? _type;
  String _department = _allDepartments;
  DateTime _date = Fmt.dateOnly(DateTime.now());
  bool _loading = false;

  Future<void> _pickDate() async {
    final d = await showDatePicker(
        context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
    if (d != null) setState(() => _date = d);
  }

  Future<void> _generate() async {
    if (!_form.currentState!.validate()) return;
    final user = sl<SessionController>().user!;
    final department = user.role == UserRole.hod
        ? user.department
        : (_department == _allDepartments ? null : _department);
    setState(() => _loading = true);
    try {
      final report = await sl<TeamRepository>().generateReport(type: _type!, date: _date, department: department);
      if (!mounted) return;
      setState(() => _loading = false);
      context.push(R.reportResult, extra: report);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      context.push(R.error, extra: e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = sl<SessionController>().user!;
    final departments = (context.watch<DepartmentsCubit>().state.data ?? const <Department>[]).map((d) => d.name).toList();
    return AppPage(
      title: 'Reports',
      bottom: PrimaryButton(label: 'Generate Report', icon: Icons.assessment_outlined, onPressed: _generate, loading: _loading),
      child: Form(
        key: _form,
        child: ListView(children: [
          Text(
            user.role == UserRole.hod
                ? 'Reports for the ${user.department} department.'
                : 'Reports for the whole organisation or a single department.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          AppDropdown<String>(
            label: 'Report Type', hint: 'Select report type', items: reportTypes,
            itemLabel: (e) => e, value: _type, onChanged: (v) => setState(() => _type = v),
            validator: (v) => v == null ? 'Select a report type' : null,
          ),
          if (user.role == UserRole.admin) ...[
            const SizedBox(height: 20),
            AppDropdown<String>(
              label: 'Department', items: [_allDepartments, ...departments],
              itemLabel: (e) => e, value: _department,
              onChanged: (v) => setState(() => _department = v ?? _allDepartments),
            ),
          ],
          const SizedBox(height: 20),
          const Text('Date', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 20),
                const SizedBox(width: 14),
                Text(Fmt.dateLong(_date)),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Weekly and monthly reports cover the week or month that contains this date.',
              style: TextStyle(fontSize: 11, color: AppColors.hint)),
        ]),
      ),
    );
  }
}
