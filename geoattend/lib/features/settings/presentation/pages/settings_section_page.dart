import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../../../auth/domain/auth_repository.dart';

/// Simple screens behind each Settings tile (no designs were provided, so
/// these are minimal and easy to replace).
class SettingsSectionPage extends StatefulWidget {
  const SettingsSectionPage({super.key, required this.section});
  final String section;

  @override
  State<SettingsSectionPage> createState() => _SettingsSectionPageState();
}

class _SettingsSectionPageState extends State<SettingsSectionPage> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  final Map<String, bool> _switches = {
    'Clock-in and clock-out reminders': true,
    'Leave and correction updates': true,
    'Attendance alerts': true,
    'Biometric login': false,
    'Two-factor authentication': false,
  };

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Widget _switchList(List<String> keys) => ListView(children: [
        for (final k in keys)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(k, style: const TextStyle(fontSize: 15)),
            value: _switches[k]!,
            activeColor: AppColors.navy,
            onChanged: (v) => setState(() => _switches[k] = v),
          ),
      ]);

  Future<void> _changePassword() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await sl<AuthRepository>().changePassword(currentPassword: _current.text, newPassword: _new.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
      context.pop();
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      context.push(R.error, extra: e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.section) {
      case 'notifications':
        return AppPage(
          title: 'Notification Preferences',
          child: _switchList(['Clock-in and clock-out reminders', 'Leave and correction updates', 'Attendance alerts']),
        );
      case 'privacy':
        return AppPage(
          title: 'Privacy and Security',
          child: _switchList(['Biometric login', 'Two-factor authentication']),
        );
      case 'password':
        return AppPage(
          title: 'Change Password',
          child: Form(
            key: _form,
            child: ListView(children: [
              AppTextField(
                label: 'Current Password', hint: 'Enter your current password', controller: _current,
                isPassword: true, validator: (v) => Validators.required(v, 'Current password'),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'New Password', hint: 'Enter your new password', controller: _new,
                isPassword: true, validator: Validators.password, onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Confirm Password', hint: 'Confirm your new password', controller: _confirm,
                isPassword: true, validator: Validators.matches(() => _new.text),
              ),
              const SizedBox(height: 20),
              PasswordRules(password: _new.text),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Update Password', onPressed: _changePassword, loading: _loading),
            ]),
          ),
        );
      case 'about':
        return AppPage(
          title: 'App Information',
          child: ListView(children: const [
            ListTile(contentPadding: EdgeInsets.zero, title: Text('GeoAttend'), subtitle: Text('Work. Verify. Be present.')),
            ListTile(contentPadding: EdgeInsets.zero, title: Text('Version'), subtitle: Text('1.0.0')),
          ]),
        );
      case 'help':
        return AppPage(
          title: 'Help & Support',
          child: ListView(children: const [
            ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.mail_outline), title: Text('Contact support'), subtitle: Text('support@geoattend.app')),
            ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.help_outline), title: Text('Clock-in not working?'),
                subtitle: Text('Turn on location services, allow location access and stand inside your workplace area, then tap Retry Location.')),
          ]),
        );
      default:
        return const AppPage(title: 'Settings', child: EmptyStateView(icon: Icons.search_off, title: 'Page not found'));
    }
  }
}
