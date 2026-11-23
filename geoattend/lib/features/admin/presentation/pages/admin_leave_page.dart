import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../../../leave/domain/leave.dart';
import '../../../leave/presentation/cubit/leave_cubit.dart';

/// HR stage of the two-stage leave approval: requests the HOD already approved.
class AdminLeavePage extends StatelessWidget {
  const AdminLeavePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Leave approvals',
      child: AsyncBuilder<LeaveCubit, LeaveData>(
        onRetry: () => context.read<LeaveCubit>().load(),
        builder: (context, data) {
          final list = data.approvals;
          if (list.isEmpty) {
            return const EmptyStateView(
              icon: Icons.event_available, title: 'Nothing to review',
              message: 'Leave requests approved by a HOD will appear here for HR approval.',
            );
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final r = list[i];
              return SoftCard(
                onTap: () => context.push(R.adminLeaveOf(r.id)),
                child: Row(children: [
                  AvatarCircle(name: r.employeeName, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.employeeName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${r.type}  |  ${Fmt.dateShort(r.start)} - ${Fmt.dateShort(r.end)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      if (r.department.isNotEmpty)
                        Text(r.department, style: const TextStyle(fontSize: 11, color: AppColors.hint)),
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
