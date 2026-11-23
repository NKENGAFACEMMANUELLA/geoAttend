import 'package:flutter/material.dart';
import 'package:geoattend/core/core.dart';

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  Color confirmColor = AppColors.navy,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      content: Text(message, style: const TextStyle(fontSize: 15)),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFFE6EEFB),
            foregroundColor: AppColors.textSecondary,
            minimumSize: const Size(110, 42),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel),
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(110, 42),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<void> confirmLogout(BuildContext context) async {
  final ok = await confirmDialog(context,
      title: 'Log Out',
      message: 'Are you sure you want to log out?',
      confirmLabel: 'Log out',
      confirmColor: AppColors.red);
  if (ok) sl<SessionController>().signOut();
}
