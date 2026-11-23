import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../../../hod/presentation/widgets/team_attendance_view.dart';
import '../../domain/admin.dart';
import '../cubit/admin_cubits.dart';
import 'employees_pages.dart';

Department? _findDepartment(List<Department>? list, String? id) {
  for (final d in list ?? const <Department>[]) {
    if (d.id == id) return d;
  }
  return null;
}

class DepartmentsPage extends StatefulWidget {
  const DepartmentsPage({super.key});

  @override
  State<DepartmentsPage> createState() => _DepartmentsPageState();
}

class _DepartmentsPageState extends State<DepartmentsPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Departments',
      child: Column(children: [
        Row(children: [
          Expanded(child: SearchField(hint: 'Search by name', onChanged: (v) => setState(() => _query = v.trim().toLowerCase()))),
          const SizedBox(width: 12),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy, foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => context.push(R.departmentNew),
              child: const Text('Add Department', style: TextStyle(fontSize: 13)),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        Expanded(
          child: AsyncBuilder<DepartmentsCubit, List<Department>>(
            onRetry: () => context.read<DepartmentsCubit>().load(),
            builder: (context, all) {
              final list = all.where((d) => _query.isEmpty || d.name.toLowerCase().contains(_query)).toList();
              if (list.isEmpty) return const EmptyStateView(icon: Icons.apartment, title: 'No departments found');
              return ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 22),
                itemBuilder: (_, i) {
                  final d = list[i];
                  return InkWell(
                    onTap: () => context.push(R.departmentOf(d.id)),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(d.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          Text('HOD, ${d.hodName}', style: const TextStyle(fontSize: 12, color: AppColors.hint)),
                          Text('${d.employeeCount} Employees', style: const TextStyle(fontSize: 12, color: AppColors.hint)),
                        ]),
                      ),
                      StatusPill.active(d.active),
                    ]),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

class DepartmentFormPage extends StatefulWidget {
  const DepartmentFormPage({super.key});

  @override
  State<DepartmentFormPage> createState() => _DepartmentFormPageState();
}

class _DepartmentFormPageState extends State<DepartmentFormPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  late final Future<List<HodCandidate>> _candidates = sl<AdminRepository>().hodCandidates();
  HodCandidate? _hod;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    try {
      await context.read<DepartmentsCubit>().save(
            Department(id: '', name: _name.text.trim(), description: _description.text.trim()),
            hod: _hod,
          );
      messenger.showSnackBar(const SnackBar(content: Text('Department added')));
      if (mounted) context.pop();
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      context.push(R.error, extra: e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Add Department',
      child: Form(
        key: _form,
        child: ListView(children: [
          AppTextField(label: 'Department Name', hint: 'Enter department name', controller: _name, validator: (v) => Validators.required(v, 'Department name')),
          const SizedBox(height: 16),
          AppTextField(label: 'Description', hint: 'Enter description (optional)', controller: _description),
          const SizedBox(height: 16),
          FutureBuilder<List<HodCandidate>>(
            future: _candidates,
            builder: (context, snap) => AppDropdown<HodCandidate>(
              label: 'Assign HOD', hint: 'Select HOD', items: snap.data ?? const [],
              itemLabel: (h) => h.name, value: _hod, onChanged: (v) => setState(() => _hod = v),
            ),
          ),
          const SizedBox(height: 32),
          ButtonPair(primaryLabel: 'Save', onPrimary: _save, onSecondary: () => context.pop(), loading: _loading),
        ]),
      ),
    );
  }
}

class DepartmentDetailsPage extends StatelessWidget {
  const DepartmentDetailsPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final dept = _findDepartment(context.watch<DepartmentsCubit>().state.data, id);
    if (dept == null) {
      return const AppPage(title: 'Department Details', child: EmptyStateView(icon: Icons.search_off, title: 'Department not found'));
    }
    final employees = (context.watch<EmployeesCubit>().state.data ?? const <Employee>[])
        .where((e) => e.department == dept.name)
        .toList();
    return DefaultTabController(
      length: 3,
      child: AppPage(
        title: 'Department Details',
        actions: [
          IconButton(
            tooltip: 'Assign HOD',
            icon: const Icon(Icons.manage_accounts_outlined),
            onPressed: () => context.push(R.hodAssignmentOf(dept.id)),
          ),
        ],
        bottom: SecondaryButton(
          label: 'View Department Reports',
          onPressed: () => context.go(R.tab(UserRole.admin, 'reports')),
        ),
        child: Column(children: [
          Row(children: [
            Container(
              width: 60, height: 60,
              decoration: const BoxDecoration(color: AppColors.skyBlue, shape: BoxShape.circle),
              child: const Icon(Icons.person_outline, color: AppColors.navy, size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(dept.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                Text('HOD, ${dept.hodName}', style: const TextStyle(fontSize: 12, color: AppColors.hint)),
                Text('${dept.employeeCount} Employees', style: const TextStyle(fontSize: 12, color: AppColors.hint)),
              ]),
            ),
            StatusPill.active(dept.active),
          ]),
          const SizedBox(height: 16),
          const TabBar(
            labelColor: AppColors.navy, unselectedLabelColor: AppColors.hint, indicatorColor: AppColors.navy,
            tabs: [Tab(text: 'Employees'), Tab(text: 'Attendance'), Tab(text: 'Reports')],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(children: [
              ListView(children: [
                InkWell(
                  onTap: () => context.push(R.employees),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Department Employees', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                      Icon(Icons.chevron_right),
                    ]),
                  ),
                ),
                if (employees.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No employees assigned yet.', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                for (final e in employees)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: EmployeeTile(employee: e, onTap: () => context.push(R.employeeEditOf(e.id))),
                  ),
              ]),
              TeamAttendanceView(department: dept.name),
              ListView(children: const [
                SizedBox(height: 16),
                Text('Generate weekly, monthly and per-employee attendance reports for this department from the Reports tab.',
                    style: TextStyle(color: AppColors.textSecondary)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class HodAssignmentPage extends StatefulWidget {
  const HodAssignmentPage({super.key, this.departmentId});
  final String? departmentId;

  @override
  State<HodAssignmentPage> createState() => _HodAssignmentPageState();
}

class _HodAssignmentPageState extends State<HodAssignmentPage> {
  late final Future<List<HodCandidate>> _candidates = sl<AdminRepository>().hodCandidates();
  late String? _deptId = widget.departmentId;
  HodCandidate? _selected;
  bool _loading = false;

  Future<void> _assign() async {
    if (_deptId == null || _selected == null) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    try {
      await context.read<DepartmentsCubit>().assignHod(_deptId!, _selected!);
      messenger.showSnackBar(SnackBar(content: Text('${_selected!.name} is now the HOD')));
      if (mounted) context.pop();
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      context.push(R.error, extra: e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final departments = context.watch<DepartmentsCubit>().state.data ?? const <Department>[];
    final dept = _findDepartment(departments, _deptId);
    return AppPage(
      title: 'HOD Assignment',
      bottom: ButtonPair(
        primaryLabel: 'Assign HOD', onPrimary: _selected == null ? null : _assign,
        onSecondary: () => context.pop(), loading: _loading,
      ),
      child: ListView(children: [
        AppDropdown<Department>(
          label: 'Department', hint: 'Select department', items: departments,
          itemLabel: (d) => d.name, value: dept,
          onChanged: (d) => setState(() {
            _deptId = d?.id;
            _selected = null;
          }),
        ),
        const SizedBox(height: 22),
        const Text('Current HOD', style: TextStyle(fontSize: 15)),
        const SizedBox(height: 12),
        if (dept == null || dept.hodName.isEmpty)
          const Text('No HOD assigned', style: TextStyle(color: AppColors.textSecondary))
        else
          _person(dept.hodName, dept.hodEmail, size: 64),
        const SizedBox(height: 24),
        const Text('Available HODs', style: TextStyle(fontSize: 15)),
        const SizedBox(height: 12),
        FutureBuilder<List<HodCandidate>>(
          future: _candidates,
          builder: (context, snap) {
            final list = (snap.data ?? const <HodCandidate>[]).where((h) => h.email != dept?.hodEmail).toList();
            if (!snap.hasData) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
            return Column(children: [
              for (final h in list)
                InkWell(
                  onTap: () => setState(() => _selected = h),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _selected == h ? AppColors.navy : Colors.transparent, width: 1.5),
                    ),
                    child: _person(h.name, h.email),
                  ),
                ),
            ]);
          },
        ),
      ]),
    );
  }

  Widget _person(String name, String email, {double size = 52}) => Row(children: [
        AvatarCircle(name: name, size: size),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 15)),
          Text(email, style: const TextStyle(fontSize: 12)),
        ]),
      ]);
}
