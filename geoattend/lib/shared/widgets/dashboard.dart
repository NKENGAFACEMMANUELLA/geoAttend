import 'package:flutter/material.dart';
import 'package:geoattend/core/core.dart';

/// White rounded card with a soft shadow.
class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: const Color(0xFF000080).withOpacity(0.07), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Tinted circle with an icon.
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, required this.color, this.size = 42});
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withOpacity(0.13), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

/// Big number with an icon, e.g. "Present 24".
class DashStatTile extends StatelessWidget {
  const DashStatTile({super.key, required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        IconBadge(icon: icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.1)),
            const SizedBox(height: 2),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
      ]),
    );
  }
}

/// Tappable icon tile. [subtitle] makes it a larger "manage" card.
class DashAction extends StatelessWidget {
  const DashAction({super.key, required this.icon, required this.label, required this.color, required this.onTap, this.subtitle});
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (subtitle != null) {
      return SoftCard(
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconBadge(icon: icon, color: color, size: 46),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            Text(subtitle!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ]),
      );
    }
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      child: Column(children: [
        IconBadge(icon: icon, color: color, size: 46),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class LegendDot extends StatelessWidget {
  const LegendDot({super.key, required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12)),
    ]);
  }
}

/// Navy gradient header with logo, bell, avatar, greeting and a subtitle chip.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.name,
    required this.subtitle,
    required this.hasUnread,
    required this.onBell,
    this.onAvatar,
  });
  final String name;
  final String subtitle;
  final bool hasUnread;
  final VoidCallback onBell;
  final VoidCallback? onAvatar;

  Widget _circle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: Colors.white.withOpacity(opacity), shape: BoxShape.circle),
      );

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return ClipRect(
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.navy, Color(0xFF1C1CB8)],
          ),
        ),
        child: Stack(children: [
          Positioned(right: -50, top: -30, child: _circle(190, 0.07)),
          Positioned(left: -40, bottom: -30, child: _circle(130, 0.05)),
          Padding(
            padding: EdgeInsets.fromLTRB(20, top + 14, 20, 34),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Text('GeoAttend', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                const Spacer(),
                GestureDetector(
                  onTap: onBell,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                    child: Stack(alignment: Alignment.center, children: [
                      const Icon(Icons.notifications_none, color: Colors.white, size: 24),
                      if (hasUnread)
                        Positioned(
                          right: 11,
                          top: 10,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: AppColors.yellow,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.navy, width: 1.5),
                            ),
                          ),
                        ),
                    ]),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onAvatar,
                  child: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Text(Fmt.initials(name),
                        style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              Text('${Fmt.greeting()},', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
              const SizedBox(height: 2),
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Navy header on top, light rounded sheet below.
class DashboardScaffold extends StatelessWidget {
  const DashboardScaffold({super.key, required this.header, required this.child});
  final Widget header;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Column(children: [
        header,
        Expanded(
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: child,
          ),
        ),
      ]),
    );
  }
}
