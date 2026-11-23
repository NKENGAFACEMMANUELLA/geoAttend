import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../cubit/auth_cubit.dart';

class VerifyCodePage extends StatefulWidget {
  const VerifyCodePage({super.key, required this.email});
  final String email;

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  static const _length = 4;
  static const _validFor = 180; // seconds
  final _controllers = List.generate(_length, (_) => TextEditingController());
  final _nodes = List.generate(_length, (_) => FocusNode());
  Timer? _timer;
  int _remaining = _validFor;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _remaining = _validFor;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
      }
      if (mounted) setState(() => _remaining = _remaining > 0 ? _remaining - 1 : 0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();
  String get _countdown =>
      '${(_remaining ~/ 60).toString().padLeft(2, '0')}:${(_remaining % 60).toString().padLeft(2, '0')}';

  void _onChanged(int i, String v) {
    if (v.isNotEmpty && i < _length - 1) _nodes[i + 1].requestFocus();
    if (v.isEmpty && i > 0) _nodes[i - 1].requestFocus();
    setState(() {});
  }

  Future<void> _verify() async {
    if (_remaining == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code expired. Tap "Send again".')));
      return;
    }
    final result = await context.read<AuthCubit>().verifyCode(widget.email, _code);
    if (!mounted) return;
    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error!)));
    } else {
      context.pushReplacement(R.reset, extra: result.token);
    }
  }

  Future<void> _resend() async {
    final error = await context.read<AuthCubit>().sendResetCode(widget.email);
    if (!mounted) return;
    if (error == null) {
      for (final c in _controllers) {
        c.clear();
      }
      _nodes.first.requestFocus();
      _startTimer();
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthCubit>().state;
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, leading: const AppBackButton()),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const Text('Check Your Email', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('We’ve sent the code to ${widget.email}',
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 28),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              for (var i = 0; i < _length; i++)
                SizedBox(
                  width: 62,
                  height: 62,
                  child: TextField(
                    controller: _controllers[i],
                    focusNode: _nodes[i],
                    autofocus: i == 0,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontSize: 26),
                    decoration: const InputDecoration(counterText: '', contentPadding: EdgeInsets.zero),
                    onChanged: (v) => _onChanged(i, v),
                  ),
                ),
            ]),
            const SizedBox(height: 16),
            Text('Code expires in : $_countdown', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 48),
            PrimaryButton(
              label: 'Verify', onPressed: _code.length == _length ? _verify : null,
              loading: loading, color: AppColors.yellow, textColor: Colors.black,
            ),
            const SizedBox(height: 14),
            SecondaryButton(label: 'Send again', onPressed: loading ? null : _resend, color: Colors.black),
          ]),
        ),
      ),
    );
  }
}
