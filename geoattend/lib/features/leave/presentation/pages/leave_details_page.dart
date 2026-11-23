import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../../domain/leave.dart';
import '../cubit/leave_cubit.dart';

/// Employee view of one of their leave requests.
class LeaveDetailsPage extends StatelessWidget {
  const LeaveDetailsPage({super.key, required this.id});
  final String id;

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 6),
        child: Text(t, style: const TextStyle(fontSize: 13, color: AppColors.hint)),
      );

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Leave Request Details',
      child: AsyncBuilder<LeaveCubit, LeaveData>(
        onRetry: () => context.read<LeaveCubit>().load(),
        builder: (context, data) {
          final r = data.find(id);
          if (r == null) {
            return const EmptyStateView(icon: Icons.search_off, title: 'Request not found');
          }
          final decision = switch (r.status) {
            RequestStatus.pending => r.stage == 'hr' ? 'Approved by your HOD, awaiting HR review' : '(awaiting review)',
            RequestStatus.approved => 'Approved by ${r.approver}',
            RequestStatus.rejected => 'Rejected by ${r.approver}',
          };
          return ListView(children: [
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.person, size: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.type, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('${Fmt.dateShort(r.start)} - ${Fmt.dateLong(r.end)} (${r.days} day${r.days == 1 ? '' : 's'})',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
            _label('Reason'),
            Text(r.reason.isEmpty ? '—' : r.reason, style: const TextStyle(fontSize: 15)),
            _label('Submitted'),
            Text(Fmt.dateTime(r.submittedAt), style: const TextStyle(fontSize: 15)),
            _label('Status'),
            Row(children: [
              CircleAvatar(radius: 14, backgroundColor: r.status.background,
                  child: Icon(Icons.circle, size: 10, color: r.status.color)),
              const SizedBox(width: 12),
              Text(r.status.label, style: TextStyle(fontSize: 15, color: r.status.color, fontWeight: FontWeight.w500)),
            ]),
            const SizedBox(height: 24),
            const Text('Review Approver', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(children: [const Icon(Icons.person, size: 22), const SizedBox(width: 10), Text(r.approver)]),
            const SizedBox(height: 24),
            const Text('Approval Decision', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(decision),
            if (r.status == RequestStatus.pending) ...[
              const SizedBox(height: 40),
              SecondaryButton(
                label: 'Cancel Request', color: AppColors.red,
                onPressed: () async {
                  final cubit = context.read<LeaveCubit>();
                  final ok = await confirmDialog(context,
                      title: 'Cancel request', message: 'Cancel this leave request?',
                      confirmLabel: 'Cancel request', cancelLabel: 'Keep', confirmColor: AppColors.red);
                  if (!ok) return;
                  await cubit.cancel(r.id);
                  if (context.mounted) context.go(UserRole.employee.homePath);
                },
              ),
            ],
          ]);
        },
      ),
    );
  }
}
