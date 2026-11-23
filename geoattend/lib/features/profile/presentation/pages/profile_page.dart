import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../widgets/edit_profile_sheet.dart';

/// Profile for Employee and HOD (admins use Company Settings).
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = sl<SessionController>();
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final u = session.user;
        if (u == null) return const SizedBox.shrink();
        final subtitle = u.role == UserRole.hod
            ? 'HOD - ${u.department}'
            : u.employeeId;
        return AppPage(
          title: 'Profile',
          showBack: false,
          actions: [
            IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => context.push(R.settings)),
          ],
          child: ListView(children: [
            const SizedBox(height: 8),
            Center(child: AvatarCircle(name: u.name, size: 100)),
            const SizedBox(height: 14),
            Center(child: Text(u.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
            const SizedBox(height: 4),
            Center(child: Text(subtitle, style: const TextStyle(fontSize: 16, color: AppColors.hint))),
            const SizedBox(height: 24),
            InfoRow(icon: Icons.mail, label: 'Email', value: u.email),
            InfoRow(icon: Icons.phone_in_talk, label: 'Phone', value: u.phone),
            InfoRow(icon: Icons.apartment, label: 'Department', value: u.department),
            InfoRow(icon: Icons.person, label: 'Role', value: u.position),
            InfoRow(icon: Icons.location_on_outlined, label: 'Workplace', value: u.workplace),
            InfoRow(
              icon: Icons.circle, label: 'Account Status', value: '',
              trailing: StatusPill.active(u.isActive),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Edit Profile', color: AppColors.paleBlue, textColor: AppColors.navy,
              onPressed: () => showEditProfileSheet(context),
            ),
          ]),
        );
      },
    );
  }
}
