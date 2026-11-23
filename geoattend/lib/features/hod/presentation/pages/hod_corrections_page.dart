import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../../../correction/domain/correction.dart';
import '../../../correction/presentation/cubit/correction_cubit.dart';

/// HOD reviews attendance correction requests from their department.
class HodCorrectionsPage extends StatelessWidget {
  const HodCorrectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Correction requests',
      child: AsyncBuilder<CorrectionApprovalsCubit, List<CorrectionRequest>>(
        onRetry: () => context.read<CorrectionApprovalsCubit>().load(),
        builder: (context, list) {
          if (list.isEmpty) {
            return const EmptyStateView(
              icon: Icons.edit_note, title: 'No correction requests',
              message: 'Requests from your team will appear here.',
            );
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _CorrectionCard(request: list[i]),
          );
        },
      ),
    );
  }
}

class _CorrectionCard extends StatefulWidget {
  const _CorrectionCard({required this.request});
  final CorrectionRequest request;

  @override
  State<_CorrectionCard> createState() => _CorrectionCardState();
}

class _CorrectionCardState extends State<_CorrectionCard> {
  bool _busy = false;

  Future<void> _decide(bool approve) async {
    final cubit = context.read<CorrectionApprovalsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmDialog(context,
        title: approve ? 'Approve correction' : 'Reject correction',
        message: approve
            ? 'The attendance record will be changed to the requested times.'
            : 'Reject this correction request?',
        confirmLabel: approve ? 'Approve' : 'Reject',
        confirmColor: approve ? AppColors.navy : AppColors.red);
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await cubit.decide(widget.request.id, approved: approve);
      messenger.showSnackBar(SnackBar(content: Text(approve ? 'Correction approved' : 'Correction rejected')));
    } on AppException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return SoftCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AvatarCircle(name: r.employeeName, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.employeeName, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(r.employeeId, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ]),
          ),
          StatusPill.request(r.status),
        ]),
        const SizedBox(height: 14),
        Text(Fmt.dateLong(r.date), style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('Recorded clock-in: ${Fmt.time(r.existingClockIn)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text('Requested: ${Fmt.time(r.requestedClockIn)} - ${Fmt.time(r.requestedClockOut)}', style: const TextStyle(fontSize: 12)),
        if (r.reason.isNotEmpty) Text('Reason: ${r.reason}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        if (r.status == RequestStatus.pending) ...[
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: _busy ? null : () => _decide(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy, foregroundColor: Colors.white, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Approve'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 42,
                child: OutlinedButton(
                  onPressed: _busy ? null : () => _decide(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy, side: const BorderSide(color: AppColors.navy),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Reject'),
                ),
              ),
            ),
          ]),
        ],
      ]),
    );
  }
}
