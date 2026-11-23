import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../cubit/auth_cubit.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _employeeId = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _email, _employeeId, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final error = await context.read<AuthCubit>().register(
        _name.text.trim(), _email.text.trim(), _employeeId.text.trim(), _password.text);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    context.go(R.success,
        extra: const SuccessArgs(
            title: 'Account created',
            message: 'You can now sign in with your email and password.',
            nextRoute: R.login));
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthCubit>().state;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Center(child: Icon(Icons.location_on, size: 72, color: AppColors.navy)),
              const Center(
                child: Text('GeoAttend',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFF00004D))),
              ),
              const Center(
                child: Text('Work. Verify. Be present.',
                    style: TextStyle(fontSize: 13, color: AppColors.navy)),
              ),
              const SizedBox(height: 24),
              const Text('Create Your Account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Join GeoAttend and start managing your attendance with ease',
                  style: TextStyle(fontSize: 14, color: Color(0xFF5B6B9A))),
              const SizedBox(height: 20),
              AppTextField(
                label: 'Full Name', hint: 'Enter your full name', controller: _name,
                validator: (v) => Validators.required(v, 'Full name'),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Email', hint: 'Enter your email address', controller: _email,
                keyboardType: TextInputType.emailAddress, validator: Validators.email,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Employee ID', hint: 'Enter your employee ID', controller: _employeeId,
                validator: (v) => Validators.required(v, 'Employee ID'),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Password', hint: 'Create your password', controller: _password,
                isPassword: true, validator: Validators.password,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Confirm Password', hint: 'Confirm your password', controller: _confirm,
                isPassword: true, validator: Validators.matches(() => _password.text),
              ),
              const SizedBox(height: 20),
              PrimaryButton(label: 'Register', onPressed: _submit, loading: loading),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Already have an account? ', style: TextStyle(fontSize: 13, color: Color(0xFF5B6B9A))),
                GestureDetector(
                  onTap: () => context.go(R.login),
                  child: const Text('Login',
                      style: TextStyle(fontSize: 13, color: AppColors.navy, fontWeight: FontWeight.w500)),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
