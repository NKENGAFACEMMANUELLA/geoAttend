import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../cubit/auth_cubit.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final email = _email.text.trim();
    final error = await context.read<AuthCubit>().sendResetCode(email);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      context.push(R.verify, extra: email);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthCubit>().state;
    return AppPage(
      title: 'Forgot Password',
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Form(
        key: _form,
        child: ListView(children: [
          const Text('Enter your email and we’ll send you a link to reset your password.',
              style: TextStyle(fontSize: 15)),
          const SizedBox(height: 24),
          AppTextField(
            label: 'Email', hint: 'Enter your Email', controller: _email,
            keyboardType: TextInputType.emailAddress, validator: Validators.email,
          ),
          const SizedBox(height: 48),
          PrimaryButton(
            label: 'Submit', onPressed: _submit, loading: loading,
            color: AppColors.yellow, textColor: Colors.black,
          ),
          TextButton(
            onPressed: () => context.go(R.login),
            child: const Text('Back to Login', style: TextStyle(color: AppColors.navy)),
          ),
        ]),
      ),
    );
  }
}
