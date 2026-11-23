import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../../../admin/domain/admin.dart';
import '../../../admin/presentation/cubit/admin_cubits.dart';
import '../../domain/team.dart';
import '../cubit/team_attendance_cubit.dart';

/// Date navigator + status filters + attendance list.
/// Used by the HOD attendance tab, the admin organisation view and the
/// department details screen. Owns its own cubit so instances don't clash.
class TeamAttendanceView extends StatelessWidget {
  const TeamAttendanceView({super.key, this.department, this.allowDepartmentFilter = false});
  final String? department;
  final bool allowDepartmentFilter;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TeamAttendanceCubit(sl<TeamRepository>()),
      child: _Body(department: department, allowDepartmentFilter: allowDepartmentFilter),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.department, required this.allowDepartmentFilter});
  final String? department;
  final bool allowDepartmentFilter;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  static const _filters = <AttendanceStatus?>[
    null, AttendanceStatus.present, AttendanceStatus.late, AttendanceStatus.absent, AttendanceStatus.leave,
  ];
  static const _labels = ['All', 'Present', 'Late', 'Absent', 'On Leave'];

  DateTime _date = Fmt.dateOnly(DateTime.now());
  int _filter = 0;
  String? _dept;

  @override
  void initState() {
    super.initState();
    _dept = widget.department;
    _load();
  }

  void _load() => context.read<TeamAttendanceCubit>().load(_date, department: _dept);

  @override
  Widget build(BuildContext context) {
    final departments = context.read<DepartmentsCubit>().state.data ?? const <Department>[];
    return Column(children: [
      DateNavigator(date: _date, onChanged: (d) {
        setState(() => _date = Fmt.dateOnly(d));
        _load();
      }),
      const SizedBox(height: 14),
      if (widget.allowDepartmentFilter) ...[
        Align(
          alignment: Alignment.centerLeft,
          child: PopupMenuButton<String>(
            onSelected: (v) {
              setState(() => _dept = v.isEmpty ? null : v);
              _load();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: '', child: Text('All Department')),
              for (final d in departments) PopupMenuItem(value: d.name, child: Text(d.name)),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_dept ?? 'All Department', style: const TextStyle(color: Colors.white, fontSize: 13)),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
      FilterTabBar(
        labels: _labels, selected: _filter, scrollable: true,
        onChanged: (i) => setState(() => _filter = i),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: AsyncBuilder<TeamAttendanceCubit, TeamData>(
          onRetry: _load,
          builder: (context, data) {
            final status = _filters[_filter];
            final rows = status == null ? data.rows : data.rows.where((r) => r.status == status).toList();
            if (rows.isEmpty) {
              return const EmptyStateView(icon: Icons.groups_outlined, title: 'No records', message: 'No employees match this filter.');
            }
            return ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final r = rows[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(children: [
                    Expanded(
                      flex: 5,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r.name, style: const TextStyle(fontSize: 15)),
                        if (r.position.isNotEmpty)
                          Text(r.position, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ]),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(r.status.label,
                          style: TextStyle(fontSize: 14, color: r.status.color, fontWeight: FontWeight.w500)),
                    ),
                    Text(r.time == null ? '---' : Fmt.time(r.time), style: const TextStyle(fontSize: 14)),
                  ]),
                );
              },
            );
          },
        ),
      ),
    ]);
  }
}
