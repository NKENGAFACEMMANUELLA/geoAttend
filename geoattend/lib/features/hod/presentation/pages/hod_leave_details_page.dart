import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../../../leave/domain/leave.dart';
import '../../../leave/presentation/cubit/leave_cubit.dart';

/// HOD reviews a team member's leave request: Approve / Reject.
class HodLeaveDetailsPage extends StatefulWidget {
  const HodLeaveDetailsPage({super.key, required this.id});
  final String id;

  @override
  State<HodLeaveDetailsPage> createState() => _HodLeaveDetailsPageState();
}

class _HodLeaveDetailsPageState extends State<HodLeaveDetailsPage> {
  bool _busy = false;

  Future<void> _decide(bool approve) async {
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<LeaveCubit>();
    final ok = await confirmDialog(context,
        title: approve ? 'Approve request' : 'Reject request',
        message: approve ? 'Approve this leave request?' : 'Reject this leave request?',
        confirmLabel: approve ? 'Approve' : 'Reject',
        confirmColor: approve ? AppColors.navy : AppColors.red);
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await cubit.decide(widget.id, approved: approve);
      messenger.showSnackBar(SnackBar(content: Text(approve ? 'Leave request approved' : 'Leave request rejected')));
      if (mounted) context.pop();
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        context.push(R.error, extra: e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Leave Request Details',
      child: AsyncBuilder<LeaveCubit, LeaveData>(
        onRetry: () => context.read<LeaveCubit>().load(),
        builder: (context, data) {
          final r = data.find(widget.id);
          if (r == null) return const EmptyStateView(icon: Icons.search_off, title: 'Request not found');
          Widget label(String t) => Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 6),
                child: Text(t, style: const TextStyle(fontSize: 14)),
              );
          return ListView(children: [
            Row(children: [
              AvatarCircle(name: r.employeeName, size: 82, color: AppColors.paleBlue),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.employeeName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${r.employeeId}  - ${r.department}', style: const TextStyle(fontSize: 14)),
              ]),
            ]),
            const SizedBox(height: 32),
            Text(r.type, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 20),
              const SizedBox(width: 10),
              Text('${Fmt.dateShort(r.start)} - ${Fmt.dateLong(r.end)} (${r.days} day${r.days == 1 ? '' : 's'})'),
            ]),
            label('Reason'),
            Text(r.reason.isEmpty ? '—' : r.reason, style: const TextStyle(color: AppColors.textSecondary)),
            label('Submitted'),
            Text(Fmt.dateTime(r.submittedAt)),
            label('Status'),
            StatusPill.request(r.status),
            const SizedBox(height: 40),
            if (r.status == RequestStatus.pending)
              Row(children: [
                Expanded(child: PrimaryButton(label: 'Approve', onPressed: _busy ? null : () => _decide(true), loading: _busy)),
                const SizedBox(width: 12),
                Expanded(child: SecondaryButton(label: 'Reject', onPressed: _busy ? null : () => _decide(false))),
              ]),
          ]);
        },
      ),
    );
  }
}
