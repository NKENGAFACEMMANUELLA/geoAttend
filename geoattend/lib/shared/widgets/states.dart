import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend/core/core.dart';

import 'buttons.dart';

class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final Widget icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 24),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
            if (onAction != null) ...[
              const SizedBox(height: 32),
              PrimaryButton(label: actionLabel ?? 'Retry', onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({super.key, required this.icon, required this.title, this.message});
  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return StateMessage(
      icon: Container(
        width: 150,
        height: 150,
        decoration: const BoxDecoration(color: AppColors.paleBlue, shape: BoxShape.circle),
        child: Icon(icon, size: 72, color: Colors.black87),
      ),
      title: title,
      message: message,
    );
  }
}

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({super.key, this.message, this.onRetry});
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return StateMessage(
      icon: const Icon(Icons.warning_rounded, size: 120, color: Color(0xFFFF3B3B)),
      title: 'Something went wrong',
      message: message ?? 'Please try again.',
      onAction: onRetry,
    );
  }
}

class NoInternetView extends StatelessWidget {
  const NoInternetView({super.key, this.onRetry});
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return StateMessage(
      icon: const Icon(Icons.cloud_off_rounded, size: 120, color: Color(0xFFCCCCCC)),
      title: 'No Internet Connection',
      message: 'Please check your internet connection and try again.',
      onAction: onRetry,
    );
  }
}

class GreenCheck extends StatelessWidget {
  const GreenCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: const BoxDecoration(color: AppColors.greenSoft, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Container(
        width: 104,
        height: 104,
        decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 64),
      ),
    );
  }
}

class SuccessArgs {
  const SuccessArgs({required this.nextRoute, this.title = 'Success!', this.message = 'Your request has been submitted successfully'});
  final String title;
  final String message;
  final String nextRoute;
}

class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key, required this.args});
  final SuccessArgs args;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StateMessage(
          icon: const GreenCheck(),
          title: args.title,
          message: args.message,
          actionLabel: 'Continue',
          onAction: () => context.go(args.nextRoute),
        ),
      ),
    );
  }
}

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ErrorStateView(
          message: message,
          onRetry: () => context.canPop() ? context.pop() : context.go(R.login),
        ),
      ),
    );
  }
}

/// Pulsing placeholder blocks shown while data loads.
class SkeletonList extends StatefulWidget {
  const SkeletonList({super.key, this.count = 5});
  final int count;

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(_c),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(color: Color(0xFFDADADA), shape: BoxShape.circle)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(height: 10, color: const Color(0xFFDADADA)),
                const SizedBox(height: 8),
                Container(height: 10, width: 120, color: const Color(0xFFDADADA)),
              ]),
            ),
          ]),
          const SizedBox(height: 20),
          for (var i = 0; i < widget.count; i++)
            Container(
              height: 76,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFE4E4E4),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
        ]),
      ),
    );
  }
}
