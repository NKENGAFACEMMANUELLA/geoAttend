import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../../../admin/domain/admin.dart';
import '../../../admin/presentation/cubit/admin_cubits.dart';
import '../../../admin/presentation/pages/employees_pages.dart';
import '../../domain/workplace.dart';
import '../cubit/workplaces_cubit.dart';

Workplace? _findWorkplace(List<Workplace>? list, String? id) {
  for (final w in list ?? const <Workplace>[]) {
    if (w.id == id) return w;
  }
  return null;
}

class WorkplacesPage extends StatefulWidget {
  const WorkplacesPage({super.key});

  @override
  State<WorkplacesPage> createState() => _WorkplacesPageState();
}

class _WorkplacesPageState extends State<WorkplacesPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Workplaces',
      child: Column(children: [
        Row(children: [
          Expanded(child: SearchField(hint: 'Search workplace', onChanged: (v) => setState(() => _query = v.trim().toLowerCase()))),
          const SizedBox(width: 12),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy, foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => context.push(R.workplaceNew),
              child: const Text('Add Workplace', style: TextStyle(fontSize: 13)),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        Expanded(
          child: AsyncBuilder<WorkplacesCubit, List<Workplace>>(
            onRetry: () => context.read<WorkplacesCubit>().load(),
            builder: (context, all) {
              final list = all.where((w) => _query.isEmpty || w.name.toLowerCase().contains(_query)).toList();
              if (list.isEmpty) return const EmptyStateView(icon: Icons.location_city, title: 'No workplaces found');
              return ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 20),
                itemBuilder: (_, i) {
                  final w = list[i];
                  return InkWell(
                    onTap: () => context.push(R.workplaceOf(w.id)),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(w.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          Text(w.address, style: const TextStyle(fontSize: 12, color: AppColors.hint)),
                        ]),
                      ),
                      StatusPill.active(w.active),
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

/// Add (id == null) and Edit workplace.
class WorkplaceFormPage extends StatefulWidget {
  const WorkplaceFormPage({super.key, this.id});
  final String? id;

  @override
  State<WorkplaceFormPage> createState() => _WorkplaceFormPageState();
}

class _WorkplaceFormPageState extends State<WorkplaceFormPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _address, _lat, _lng, _radius;
  Workplace? _existing;
  bool _active = true;
  bool _loading = false;

  bool get _isEdit => widget.id != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _existing = _findWorkplace(context.read<WorkplacesCubit>().state.data, widget.id);
    final w = _existing;
    _name = TextEditingController(text: w?.name);
    _address = TextEditingController(text: w?.address);
    _lat = TextEditingController(text: w?.latitude.toString());
    _lng = TextEditingController(text: w?.longitude.toString());
    _radius = TextEditingController(text: w?.radius.round().toString());
    _active = w?.active ?? true;
  }

  @override
  void dispose() {
    for (final c in [_name, _address, _lat, _lng, _radius]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    try {
      await context.read<WorkplacesCubit>().save(Workplace(
            id: _existing?.id ?? '', name: _name.text.trim(), address: _address.text.trim(),
            latitude: double.parse(_lat.text.trim()), longitude: double.parse(_lng.text.trim()),
            radius: double.parse(_radius.text.trim()), active: _active,
          ));
      messenger.showSnackBar(SnackBar(content: Text(_isEdit ? 'Workplace updated' : 'Workplace added')));
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
      return const AppPage(title: 'Edit Workplace', child: EmptyStateView(icon: Icons.search_off, title: 'Workplace not found'));
    }
    const numeric = TextInputType.numberWithOptions(decimal: true, signed: true);
    return AppPage(
      title: _isEdit ? 'Edit Workplace' : 'Add Workplace',
      bottom: ButtonPair(primaryLabel: 'Save', onPrimary: _save, onSecondary: () => context.pop(), loading: _loading),
      child: Form(
        key: _form,
        child: ListView(children: [
          AppTextField(label: 'Workplace Name', hint: 'Enter Workplace Name', controller: _name, validator: (v) => Validators.required(v, 'Name')),
          const SizedBox(height: 14),
          AppTextField(label: 'Address', hint: 'Enter Address', controller: _address, validator: (v) => Validators.required(v, 'Address')),
          const SizedBox(height: 14),
          AppTextField(label: 'Latitude', hint: 'Enter Latitude', controller: _lat, keyboardType: numeric, validator: Validators.latitude),
          const SizedBox(height: 14),
          AppTextField(label: 'Longitude', hint: 'Enter Longitude', controller: _lng, keyboardType: numeric, validator: Validators.longitude),
          const SizedBox(height: 14),
          AppTextField(label: 'Geofence Radius (meters)', hint: 'Enter Radius (50 - 500)', controller: _radius, keyboardType: TextInputType.number, validator: Validators.radius),
          if (_isEdit)
            SwitchListTile(
              contentPadding: EdgeInsets.zero, title: const Text('Active'),
              value: _active, activeColor: AppColors.navy, onChanged: (v) => setState(() => _active = v),
            ),
        ]),
      ),
    );
  }
}

class WorkplaceDetailsPage extends StatelessWidget {
  const WorkplaceDetailsPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final w = _findWorkplace(context.watch<WorkplacesCubit>().state.data, id);
    if (w == null) {
      return const AppPage(title: 'Workplace Details', child: EmptyStateView(icon: Icons.search_off, title: 'Workplace not found'));
    }
    final assigned = (context.watch<EmployeesCubit>().state.data ?? const <Employee>[])
        .where((e) => e.workplace == w.name)
        .toList();
    return AppPage(
      title: 'Workplace Details',
      bottom: SecondaryButton(label: 'Edit', onPressed: () => context.push(R.workplaceEditOf(w.id))),
      child: ListView(children: [
        const Center(child: Icon(Icons.location_on, size: 72, color: AppColors.navy)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(w.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          StatusPill.active(w.active),
        ]),
        const SizedBox(height: 6),
        Text(w.address, style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 4),
        Text('Geofence radius: ${w.radius.round()}m', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        InkWell(
          onTap: () => context.push(R.employees),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Assigned Employees', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
              Icon(Icons.chevron_right),
            ]),
          ),
        ),
        if (assigned.isEmpty)
          const Padding(padding: EdgeInsets.all(8), child: Text('No employees assigned yet.', style: TextStyle(color: AppColors.textSecondary))),
        for (final e in assigned)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              AvatarCircle(name: e.name, size: 52),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.name),
                Text(e.email, style: const TextStyle(fontSize: 12)),
              ]),
            ]),
          ),
      ]),
    );
  }
}
