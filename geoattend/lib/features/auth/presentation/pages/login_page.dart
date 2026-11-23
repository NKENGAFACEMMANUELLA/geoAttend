import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../cubit/auth_cubit.dart';

/// One login screen for all three roles.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.role = UserRole.employee});
  final UserRole role;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final error = await context.read<AuthCubit>().login(_email.text.trim(), _password.text, widget.role);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Widget _header() {
    if (widget.role == UserRole.employee) {
      return const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Welcome Back,', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500)),
        SizedBox(height: 4),
        Text('Sign in to your account', style: TextStyle(fontSize: 15)),
      ]);
    }
    return Center(
      child: Column(children: [
        const Icon(Icons.location_on, size: 72, color: AppColors.navy),
        const Text('Welcome Back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(widget.role == UserRole.hod ? 'HOD Login' : 'Admin Login', style: const TextStyle(fontSize: 15)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthCubit>().state;
    final isEmployee = widget.role == UserRole.employee;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _header(),
              const SizedBox(height: 40),
              AppTextField(
                label: 'Email', hint: 'Enter your Email', controller: _email,
                keyboardType: TextInputType.emailAddress, validator: Validators.email,
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: 'Password', hint: 'Enter your password', controller: _password,
                isPassword: true, validator: (v) => Validators.required(v, 'Password'),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(R.forgot),
                  child: const Text('Forgot Password?', style: TextStyle(color: AppColors.navy)),
                ),
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Login', onPressed: _submit, loading: loading,
                color: AppColors.yellow, textColor: Colors.black,
              ),
              if (isEmployee) ...[
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () => context.push(R.register),
                    child: const Text('Create One',
                        style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w500)),
                  ),
                ]),
              ],
              const SizedBox(height: 32),
              Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
                const Text('Sign in as ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                for (final entry in {
                  if (!isEmployee) 'Employee': R.login,
                  if (widget.role != UserRole.hod) 'HOD': R.loginHod,
                  if (widget.role != UserRole.admin) 'Admin': R.loginAdmin,
                }.entries)
                  TextButton(
                    onPressed: () => context.go(entry.value),
                    child: Text(entry.key, style: const TextStyle(fontSize: 13, color: AppColors.navy)),
                  ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
