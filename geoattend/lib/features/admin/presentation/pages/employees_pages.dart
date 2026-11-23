import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../../../workplace/domain/workplace.dart';
import '../../../workplace/presentation/cubit/workplaces_cubit.dart';
import '../../domain/admin.dart';
import '../cubit/admin_cubits.dart';

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({super.key});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  int _tab = 0; // All, Active, Inactive
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Employees',
      actions: [
        IconButton(
          tooltip: 'Add employee',
          icon: const Icon(Icons.person_add_alt_1_outlined),
          onPressed: () => context.push(R.employeeNew),
        ),
      ],
      child: Column(children: [
        SearchField(onChanged: (v) => setState(() => _query = v.trim().toLowerCase())),
        const SizedBox(height: 14),
        FilterTabBar(labels: const ['All', 'Active', 'Inactive'], selected: _tab, onChanged: (i) => setState(() => _tab = i)),
        const SizedBox(height: 16),
        Expanded(
          child: AsyncBuilder<EmployeesCubit, List<Employee>>(
            onRetry: () => context.read<EmployeesCubit>().load(),
            builder: (context, all) {
              final list = all.where((e) {
                if (_tab == 1 && !e.active) return false;
                if (_tab == 2 && e.active) return false;
                return _query.isEmpty ||
                    e.name.toLowerCase().contains(_query) ||
                    e.code.toLowerCase().contains(_query);
              }).toList();
              if (list.isEmpty) {
                return const EmptyStateView(icon: Icons.groups_outlined, title: 'No employees found');
              }
              return ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (_, i) => EmployeeTile(employee: list[i], onTap: () => context.push(R.employeeEditOf(list[i].id))),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class EmployeeTile extends StatelessWidget {
  const EmployeeTile({super.key, required this.employee, this.onTap});
  final Employee employee;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CardBox(
      onTap: onTap,
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(children: [
        AvatarCircle(size: 40),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(employee.name, style: const TextStyle(fontSize: 14)),
            Text(employee.code, style: const TextStyle(fontSize: 11, color: AppColors.hint)),
          ]),
        ),
        StatusPill.active(employee.active),
      ]),
    );
  }
}

/// Add (id == null) and Edit employee.
class EmployeeFormPage extends StatefulWidget {
  const EmployeeFormPage({super.key, this.id});
  final String? id;

  @override
  State<EmployeeFormPage> createState() => _EmployeeFormPageState();
}

class _EmployeeFormPageState extends State<EmployeeFormPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _code, _email, _phone;
  Employee? _existing;
  String? _department, _position, _workplace;
  bool _active = true;
  bool _loading = false;

  bool get _isEdit => widget.id != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final list = context.read<EmployeesCubit>().state.data ?? const <Employee>[];
      final match = list.where((e) => e.id == widget.id);
      _existing = match.isEmpty ? null : match.first;
    }
    final e = _existing;
    _name = TextEditingController(text: e?.name);
    _code = TextEditingController(text: e?.code);
    _email = TextEditingController(text: e?.email);
    _phone = TextEditingController(text: e?.phone);
    _department = e?.department;
    _position = e?.position;
    _workplace = e?.workplace;
    _active = e?.active ?? true;
  }

  @override
  void dispose() {
    for (final c in [_name, _code, _email, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    try {
      await context.read<EmployeesCubit>().save(Employee(
            id: _existing?.id ?? '', name: _name.text.trim(), code: _code.text.trim(),
            email: _email.text.trim(), phone: _phone.text.trim(), department: _department!,
            position: _position!, workplace: _workplace!, active: _active,
          ));
      messenger.showSnackBar(SnackBar(
        content: Text(_isEdit
            ? 'Employee updated'
            : 'Employee added. They can set a password with "Forgot Password" on the login screen.'),
        duration: Duration(seconds: _isEdit ? 3 : 6),
      ));
      if (mounted) context.pop();
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      context.push(R.error, extra: e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEdit && _existing == null) {
      return const AppPage(title: 'Edit Employee', child: EmptyStateView(icon: Icons.search_off, title: 'Employee not found'));
    }
    final departments = (context.watch<DepartmentsCubit>().state.data ?? const <Department>[]).map((d) => d.name).toList();
    final workplaces = (context.watch<WorkplacesCubit>().state.data ?? const <Workplace>[]).map((w) => w.name).toList();
    String? req(String? v) => v == null ? 'Required' : null;
    return AppPage(
      title: _isEdit ? 'Edit Employee' : 'Add Employee',
      child: Form(
        key: _form,
        child: ListView(children: [
          AppTextField(label: 'Full Name', hint: 'Enter Name', controller: _name, validator: (v) => Validators.required(v, 'Name')),
          const SizedBox(height: 14),
          AppTextField(label: 'Employee ID', hint: 'Enter the ID', controller: _code, validator: (v) => Validators.required(v, 'Employee ID')),
          const SizedBox(height: 14),
          AppTextField(label: 'Email', hint: 'Enter email address', controller: _email, keyboardType: TextInputType.emailAddress, validator: Validators.email),
          const SizedBox(height: 14),
          AppTextField(label: 'Phone', hint: 'Enter phone number', controller: _phone, keyboardType: TextInputType.phone, validator: Validators.phone),
          const SizedBox(height: 14),
          AppDropdown<String>(label: 'Department', hint: 'Select department', items: departments, itemLabel: (e) => e, value: _department, validator: req, onChanged: (v) => setState(() => _department = v)),
          const SizedBox(height: 14),
          AppDropdown<String>(label: 'Role', hint: 'Select role', items: employeeRoles, itemLabel: (e) => e, value: _position, validator: req, onChanged: (v) => setState(() => _position = v)),
          const SizedBox(height: 14),
          AppDropdown<String>(label: 'Workplace', hint: 'Select Workplace', items: workplaces, itemLabel: (e) => e, value: _workplace, validator: req, onChanged: (v) => setState(() => _workplace = v)),
          if (_isEdit)
            SwitchListTile(
              contentPadding: EdgeInsets.zero, title: const Text('Active account'),
              value: _active, activeColor: AppColors.navy, onChanged: (v) => setState(() => _active = v),
            ),
          const SizedBox(height: 20),
          ButtonPair(
            primaryLabel: _isEdit ? 'Save Changes' : 'Save', onPrimary: _save,
            onSecondary: () => context.pop(), loading: _loading,
          ),
        ]),
      ),
    );
  }
}
