import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geoattend/core/core.dart';

/// Month grid with month/year dropdowns. Days are tinted by attendance status.
class AttendanceCalendar extends StatelessWidget {
  const AttendanceCalendar({
    super.key,
    required this.month,
    required this.statusByDay,
    required this.selected,
    required this.onMonthChanged,
    required this.onDaySelected,
  });

  final DateTime month; // first day of the visible month
  final Map<int, AttendanceStatus> statusByDay;
  final DateTime? selected;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final lead = DateTime(month.year, month.month, 1).weekday % 7; // Sunday first
    final days = DateTime(month.year, month.month + 1, 0).day;
    final nowYear = DateTime.now().year;
    const weekdays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

    Widget cell(int i) {
      if (i < lead) return const SizedBox.shrink();
      final day = i - lead + 1;
      final date = DateTime(month.year, month.month, day);
      final status = statusByDay[day];
      final isSelected = selected != null && Fmt.sameDay(selected!, date);
      return GestureDetector(
        onTap: () => onDaySelected(date),
        child: Container(
          margin: const EdgeInsets.all(3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2B2B2B) : (status?.background.withOpacity(0.6) ?? Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('$day',
              style: TextStyle(fontSize: 14, color: isSelected ? Colors.white : Colors.black)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => onMonthChanged(DateTime(month.year, month.month - 1)),
          ),
          _box(DropdownButton<int>(
            value: month.month,
            underline: const SizedBox.shrink(),
            isDense: true,
            items: [
              for (var m = 1; m <= 12; m++)
                DropdownMenuItem(value: m, child: Text(DateFormat.MMM().format(DateTime(2000, m)))),
            ],
            onChanged: (m) => onMonthChanged(DateTime(month.year, m!)),
          )),
          const SizedBox(width: 8),
          _box(DropdownButton<int>(
            value: month.year,
            underline: const SizedBox.shrink(),
            isDense: true,
            items: [
              for (var y = nowYear - 3; y <= nowYear + 1; y++) DropdownMenuItem(value: y, child: Text('$y')),
            ],
            onChanged: (y) => onMonthChanged(DateTime(y!, month.month)),
          )),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => onMonthChanged(DateTime(month.year, month.month + 1)),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          for (final d in weekdays)
            Expanded(child: Center(child: Text(d, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)))),
        ]),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [for (var i = 0; i < lead + days; i++) cell(i)],
        ),
      ]),
    );
  }

  Widget _box(Widget child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      );
}
