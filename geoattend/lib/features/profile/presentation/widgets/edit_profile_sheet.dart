import 'package:flutter/material.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../../../auth/domain/auth_repository.dart';

Future<void> showEditProfileSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => const _EditProfileSheet(),
  );
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: sl<SessionController>().user!.name);
  late final _phone = TextEditingController(text: sl<SessionController>().user!.phone);

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool _saving = false;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final session = sl<SessionController>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final updated = await sl<AuthRepository>().updateProfile(name: _name.text.trim(), phone: _phone.text.trim());
      session.update(updated);
      navigator.pop();
    } on AppException catch (e) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          AppTextField(label: 'Full Name', controller: _name, validator: (v) => Validators.required(v, 'Name')),
          const SizedBox(height: 14),
          AppTextField(
              label: 'Phone', controller: _phone, keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty) ? null : Validators.phone(v)),
          const SizedBox(height: 20),
          ButtonPair(primaryLabel: 'Save', onPrimary: _save, loading: _saving),
        ]),
      ),
    );
  }
}
