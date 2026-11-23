import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../cubit/auth_cubit.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, required this.token});
  final String token;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final error = await context.read<AuthCubit>().resetPassword(widget.token, _password.text);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      context.go(R.success,
          extra: const SuccessArgs(
              title: 'Password updated',
              message: 'Sign in with your new password.',
              nextRoute: R.login));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthCubit>().state;
    return AppPage(
      title: 'Reset Password',
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Form(
        key: _form,
        child: ListView(children: [
          const Text('Create a new password for your account', style: TextStyle(fontSize: 15)),
          const SizedBox(height: 24),
          AppTextField(
            label: 'New Password', hint: 'Enter your password', controller: _password,
            isPassword: true, validator: Validators.password, onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Confirm Password', hint: 'Enter your password', controller: _confirm,
            isPassword: true, validator: Validators.matches(() => _password.text),
          ),
          const SizedBox(height: 24),
          PasswordRules(password: _password.text),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Reset Password', onPressed: _submit, loading: loading,
            color: AppColors.yellow, textColor: Colors.black,
          ),
        ]),
      ),
    );
  }
}
