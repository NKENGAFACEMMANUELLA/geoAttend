import 'package:flutter/material.dart';
import 'package:geoattend/core/core.dart';

class StatusPill extends StatelessWidget {
  const StatusPill(this.label,
      {super.key, required this.color, required this.background, this.large = false});

  final String label;
  final Color color;
  final Color background;
  final bool large;

  factory StatusPill.request(RequestStatus s, {Key? key}) =>
      StatusPill(s.label, key: key, color: s.color, background: s.background, large: true);

  factory StatusPill.attendance(AttendanceStatus s, {Key? key}) =>
      StatusPill(s.label, key: key, color: s.color, background: s.background);

  factory StatusPill.active(bool active, {Key? key}) => StatusPill(
        active ? 'Active' : 'Inactive',
        key: key,
        color: active ? AppColors.greenDark : AppColors.red,
        background: active ? const Color(0xFFE3F5EC) : const Color(0xFFFDE8E8),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 18 : 14, vertical: large ? 10 : 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(large ? 8 : 20),
        boxShadow: large
            ? [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 3, offset: const Offset(0, 2))]
            : null,
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: large ? 14 : 12, color: color, fontWeight: FontWeight.w500)),
    );
  }
}
