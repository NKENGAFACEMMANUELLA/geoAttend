import 'package:flutter/material.dart';
import 'package:geoattend/core/core.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.navy,
    this.textColor = Colors.white,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          disabledBackgroundColor: color.withOpacity(0.55),
          disabledForegroundColor: textColor.withOpacity(0.8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: loading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: textColor))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                  Text(label,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                ],
              ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.navy,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

/// Save / Cancel (or Approve / Reject) side by side.
class ButtonPair extends StatelessWidget {
  const ButtonPair({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel = 'Cancel',
    this.onSecondary,
    this.loading = false,
    this.primaryColor = AppColors.navy,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String secondaryLabel;
  final VoidCallback? onSecondary;
  final bool loading;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
          child: PrimaryButton(
              label: primaryLabel, onPressed: onPrimary, loading: loading, color: primaryColor)),
      const SizedBox(width: 12),
      Expanded(
          child: SecondaryButton(
              label: secondaryLabel,
              onPressed: loading ? null : (onSecondary ?? () => Navigator.of(context).maybePop()))),
    ]);
  }
}
