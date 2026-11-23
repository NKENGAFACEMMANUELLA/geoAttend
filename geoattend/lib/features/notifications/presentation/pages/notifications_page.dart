import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../../domain/notification.dart';
import '../cubit/notifications_cubit.dart';
import '../widgets/notification_style.dart';

/// Shared by Employee, HOD and Admin.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int _tab = 0; // 0 All, 1 Unread, 2 Read

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Notifications',
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      actions: [
        TextButton(
          onPressed: () => context.read<NotificationsCubit>().markAllRead(),
          child: const Text('Mark all as read', style: TextStyle(color: AppColors.navy, fontSize: 14)),
        ),
      ],
      child: AsyncBuilder<NotificationsCubit, List<AppNotification>>(
        onRetry: () => context.read<NotificationsCubit>().load(),
        builder: (context, all) {
          if (all.isEmpty) {
            return const EmptyStateView(
              icon: Icons.chat_bubble_outline,
              title: 'No Notifications',
              message: 'We’ll let you know when there will be something to update you.',
            );
          }
          final list = switch (_tab) {
            1 => all.where((n) => !n.read).toList(),
            2 => all.where((n) => n.read).toList(),
            _ => all,
          };
          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilterTabBar(
                  labels: const ['All', 'Unread', 'Read'], selected: _tab, onChanged: (i) => setState(() => _tab = i)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Align(alignment: Alignment.centerLeft, child: Text('Today', style: TextStyle(fontSize: 14))),
            ),
            Expanded(
              child: list.isEmpty
                  ? const EmptyStateView(icon: Icons.notifications_off_outlined, title: 'Nothing here')
                  : ListView(children: [for (final n in list) _NotificationTile(n: n)]),
            ),
          ]);
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.n});
  final AppNotification n;

  @override
  Widget build(BuildContext context) {
    final style = NotificationStyle.of(n.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      color: n.read ? Colors.transparent : AppColors.lavender,
      child: InkWell(
        onTap: n.read ? null : () => context.read<NotificationsCubit>().markRead(n.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: style.background, shape: BoxShape.circle),
              child: Icon(style.icon, color: style.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(n.body, style: const TextStyle(fontSize: 12)),
              ]),
            ),
            const SizedBox(width: 8),
            Text(Fmt.ago(n.time), style: const TextStyle(fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}
