import 'package:flutter/material.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../../../profile/presentation/widgets/edit_profile_sheet.dart';

/// Admin "Profile" tab.
class CompanySettingsPage extends StatelessWidget {
  const CompanySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = sl<SessionController>();
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final u = session.user;
        if (u == null) return const SizedBox.shrink();
        Widget row(String label, String value) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                Text(value, style: const TextStyle(fontSize: 14)),
              ]),
            );
        return AppPage(
          title: 'Company Settings',
          showBack: false,
          child: ListView(children: [
            const SizedBox(height: 16),
            Row(children: [
              AvatarCircle(name: u.name, size: 110),
              const SizedBox(width: 20),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(u.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                  Text(u.email, style: const TextStyle(fontSize: 13)),
                ]),
              ),
            ]),
            const SizedBox(height: 40),
            row('Role', u.position),
            row('Organisation', u.organisation),
            row('Phone', u.phone),
            const SizedBox(height: 24),
            SecondaryButton(label: 'Edit Profile', onPressed: () => showEditProfileSheet(context)),
            const SizedBox(height: 28),
            Center(
              child: TextButton(
                onPressed: () => confirmLogout(context),
                child: const Text('Logout', style: TextStyle(color: AppColors.red, fontSize: 15)),
              ),
            ),
          ]),
        );
      },
    );
  }
}
