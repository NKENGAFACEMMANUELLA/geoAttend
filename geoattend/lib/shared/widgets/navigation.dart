import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend/core/core.dart';

/// Back arrow that falls back to the role's home when nothing is on the stack.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(sl<SessionController>().role?.homePath ?? R.login);
        }
      },
    );
  }
}

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.showBack = true,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 16),
    this.bottom,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool showBack;
  final EdgeInsets padding;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBack ? const AppBackButton() : null,
        titleSpacing: showBack ? 0 : 16,
        title: Text(title),
        actions: actions,
      ),
      body: SafeArea(
        child: Column(children: [
          Expanded(child: Padding(padding: padding, child: child)),
          if (bottom != null)
            Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: bottom),
        ]),
      ),
    );
  }
}

/// "< Apr 26, 2025 >" control used by attendance and summary screens.
class DateNavigator extends StatelessWidget {
  const DateNavigator({super.key, required this.date, required this.onChanged});
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final isToday = !Fmt.dateOnly(date).isBefore(Fmt.dateOnly(DateTime.now()));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black87),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => onChanged(date.subtract(const Duration(days: 1)))),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) onChanged(picked);
            },
            child: Text(Fmt.dateLong(date), style: const TextStyle(fontSize: 15)),
          ),
          IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: isToday ? null : () => onChanged(date.add(const Duration(days: 1)))),
        ],
      ),
    );
  }
}

/// Outlined tab buttons (All / Unread / Read, Pending / Approved ...).
class FilterTabBar extends StatelessWidget {
  const FilterTabBar({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.scrollable = false,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  final bool scrollable;

  Widget _tab(int i) {
    final active = i == selected;
    return GestureDetector(
      onTap: () => onChanged(i),
      child: Container(
        height: 40,
        padding: scrollable ? const EdgeInsets.symmetric(horizontal: 16) : null,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.navy : Colors.transparent,
          border: Border.all(color: active ? AppColors.navy : Colors.black87),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(labels[i],
            style: TextStyle(fontSize: 13, color: active ? Colors.white : Colors.black)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (var i = 0; i < labels.length; i++)
            Padding(padding: const EdgeInsets.only(right: 8), child: _tab(i)),
        ]),
      );
    }
    return Row(children: [
      for (var i = 0; i < labels.length; i++)
        Expanded(
            child: Padding(
                padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 8),
                child: _tab(i))),
    ]);
  }
}
