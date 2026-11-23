import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../../../correction/domain/correction.dart';
import '../../../correction/presentation/cubit/correction_cubit.dart';
import '../../../leave/domain/leave.dart';
import '../../../leave/presentation/cubit/leave_cubit.dart';

/// Employee tab that replaces "Reports": everything the employee has asked for.
class MyRequestsPage extends StatelessWidget {
  const MyRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Requests'),
          bottom: const TabBar(
            labelColor: AppColors.navy,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.navy,
            tabs: [Tab(text: 'Leave'), Tab(text: 'Corrections')],
          ),
        ),
        body: const TabBarView(children: [_LeaveTab(), _CorrectionTab()]),
      ),
    );
  }
}

class _TabLayout extends StatelessWidget {
  const _TabLayout({required this.list, required this.buttonLabel, required this.onNew});
  final Widget list;
  final String buttonLabel;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(child: list),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: PrimaryButton(label: buttonLabel, icon: Icons.add, onPressed: onNew),
      ),
    ]);
  }
}

class _LeaveTab extends StatelessWidget {
  const _LeaveTab();

  @override
  Widget build(BuildContext context) {
    return _TabLayout(
      buttonLabel: 'New leave request',
      onNew: () => context.push(R.leaveNew),
      list: AsyncBuilder<LeaveCubit, LeaveData>(
        onRetry: () => context.read<LeaveCubit>().load(),
        builder: (context, data) {
          if (data.mine.isEmpty) {
            return const EmptyStateView(
              icon: Icons.beach_access_outlined, title: 'No leave requests yet',
              message: 'Requests you submit will show up here with their status.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: data.mine.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final r = data.mine[i];
              return SoftCard(
                onTap: () => context.push(R.leaveOf(r.id)),
                child: Row(children: [
                  const IconBadge(icon: Icons.beach_access_outlined, color: AppColors.navy),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.type, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${Fmt.dateShort(r.start)} - ${Fmt.dateLong(r.end)}  (${r.days} day${r.days == 1 ? '' : 's'})',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ]),
                  ),
                  StatusPill.request(r.status),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}

class _CorrectionTab extends StatelessWidget {
  const _CorrectionTab();

  @override
  Widget build(BuildContext context) {
    return _TabLayout(
      buttonLabel: 'New correction request',
      onNew: () => context.push(R.correctionNew),
      list: AsyncBuilder<CorrectionCubit, List<CorrectionRequest>>(
        onRetry: () => context.read<CorrectionCubit>().load(),
        builder: (context, list) {
          if (list.isEmpty) {
            return const EmptyStateView(
              icon: Icons.edit_note, title: 'No correction requests yet',
              message: 'Ask for a fix if your clock-in or clock-out time is wrong.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final r = list[i];
              return SoftCard(
                child: Row(children: [
                  const IconBadge(icon: Icons.edit_note, color: AppColors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(Fmt.dateLong(r.date), style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${Fmt.time(r.requestedClockIn)} - ${Fmt.time(r.requestedClockOut)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ]),
                  ),
                  StatusPill.request(r.status),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}
