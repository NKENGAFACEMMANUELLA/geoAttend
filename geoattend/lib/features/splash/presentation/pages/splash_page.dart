import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend/core/core.dart';

import '../../../auth/domain/auth_repository.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..forward();

  bool _connecting = false;
  bool _slow = false;
  bool _left = false;
  Timer? _slowTimer;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) _continue();
    });
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    _c.dispose();
    super.dispose();
  }

  /// Tries to sign the user back in from the saved login, but never waits forever:
  /// after 12 seconds, or on ANY error, it simply opens the login screen.
  Future<void> _continue() async {
    final session = sl<SessionController>();
    if (!session.isLoggedIn) {
      setState(() => _connecting = true);
      _slowTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => _slow = true);
      });
      try {
        final user = await sl<AuthRepository>().restoreSession().timeout(const Duration(seconds: 12));
        if (user != null) session.signIn(user);
      } catch (_) {
        // Server unreachable, too slow, or the saved login could not be read: show the login screen.
      }
      _slowTimer?.cancel();
    }
    _go();
  }

  void _go() {
    if (!mounted || _left) return;
    _left = true;
    final session = sl<SessionController>();
    context.go(session.isLoggedIn ? session.role!.homePath : R.login);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(children: [
        Positioned(
          left: -w * 0.35,
          top: -w * 0.45,
          child: Container(
            width: w * 0.95,
            height: w * 0.95,
            decoration: const BoxDecoration(color: AppColors.navy, shape: BoxShape.circle),
          ),
        ),
        const Center(
          child: Text('GEOATTEND',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.navy)),
        ),
        Positioned(
          left: 52,
          right: 52,
          bottom: size.height * 0.24,
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _c.value,
                minHeight: 5,
                backgroundColor: const Color(0xFFE0E0E0),
                color: AppColors.navy,
              ),
            ),
          ),
        ),
        if (_connecting)
          Positioned(
            left: 24,
            right: 24,
            bottom: size.height * 0.08,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Connecting to server...',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              if (_slow) ...[
                const SizedBox(height: 6),
                const Text('This is taking longer than usual. The server may be off or the address may be wrong.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                TextButton(onPressed: _go, child: const Text('Continue to login')),
              ],
            ]),
          ),
      ]),
    );
  }
}
