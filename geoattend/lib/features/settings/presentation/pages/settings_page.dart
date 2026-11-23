import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, String title, String subtitle, String section) => Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Material(
            color: AppColors.background,
            elevation: 2,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => context.push(R.settingsOf(section)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(children: [
                  Icon(icon, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.hint)),
                    ]),
                  ),
                  const Icon(Icons.chevron_right),
                ]),
              ),
            ),
          ),
        );

    return AppPage(
      title: 'Settings',
      child: ListView(children: [
        const SizedBox(height: 8),
        tile(Icons.notifications_none, 'Notification Preferences', 'Manage your notifications', 'notifications'),
        tile(Icons.key, 'Change Password', 'Update your password', 'password'),
        tile(Icons.security, 'Privacy and Security', 'Biometric, 2FA etc', 'privacy'),
        tile(Icons.info, 'App Information', 'Version 1.0.0', 'about'),
        tile(Icons.help_outline, 'Help & Support', 'Get help or contact support', 'help'),
        InkWell(
          onTap: () => confirmLogout(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(children: [
              CircleAvatar(radius: 20, backgroundColor: AppColors.redSoft, child: Icon(Icons.logout, color: AppColors.red)),
              SizedBox(width: 24),
              Text('Logout', style: TextStyle(color: AppColors.red, fontSize: 15, fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      ]),
    );
  }
}
