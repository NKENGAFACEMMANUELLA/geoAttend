import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import 'location_verification_page.dart';

class ClockResultPage extends StatelessWidget {
  const ClockResultPage({super.key, required this.args});
  final ClockResultArgs args;

  @override
  Widget build(BuildContext context) {
    final r = args.record;
    final when = args.isClockIn ? r.clockIn : r.clockOut;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const GreenCheck(),
                    const SizedBox(height: 28),
                    Text(args.isClockIn ? 'Clock-In Successful' : 'Clock-Out Successful',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, letterSpacing: 1.5)),
                    const SizedBox(height: 16),
                    if (when != null)
                      Text(Fmt.dateTime(when).replaceFirst('  ', ' . '),
                          style: const TextStyle(color: AppColors.hint, fontSize: 15, letterSpacing: 1.2)),
                    const SizedBox(height: 16),
                    if (!args.isClockIn && r.hoursWorked != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))],
                        ),
                        child: Text.rich(TextSpan(children: [
                          const TextSpan(text: 'Total Hours : '),
                          TextSpan(text: Fmt.duration(r.hoursWorked!), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ])),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.location_on_outlined, color: args.isClockIn ? Colors.black : AppColors.navy),
                      const SizedBox(width: 6),
                      Text(r.workplace, style: const TextStyle(fontSize: 16)),
                    ]),
                    if (r.source == 'Offline') ...[
                      const SizedBox(height: 12),
                      const Text('Saved offline. It will sync when you are back online.',
                          style: TextStyle(color: AppColors.amber, fontSize: 13)),
                    ],
                    if (args.isClockIn) ...[
                      const SizedBox(height: 12),
                      const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.location_on, color: AppColors.greenDark),
                        SizedBox(width: 6),
                        Text('Location verified'),
                      ]),
                    ],
                  ]),
                ),
              ),
            ),
            PrimaryButton(label: 'Continue', onPressed: () => context.go(UserRole.employee.homePath)),
          ]),
        ),
      ),
    );
  }
}
