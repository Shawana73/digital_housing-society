import 'package:flutter/material.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/premium_widgets.dart';
import '../../widgets/app_snack.dart';
import '../../models/admin_models.dart';

// Icon colours for Quick Action items
const List<Color> kDashboardActionColors = [
  Color(0xFF7B4DFF),
];

/// Two-line section label.
class DashboardLabel extends StatelessWidget {
  final String title;
  final String subtitle;
  const DashboardLabel({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title,    style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -.4)),
      const SizedBox(height: 2),
      Text(subtitle, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 12)),
    ],
  );
}

/// Filled purple pill button.
class DashboardPillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const DashboardPillButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(color: AdminColors.primary, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: AdminColors.white, fontWeight: FontWeight.w800, fontSize: 13)),
    ),
  );
}

/// Green pill badge (e.g. "↑ 32%").
class DashboardGreenBadge extends StatelessWidget {
  final String label;
  const DashboardGreenBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: AdminColors.success.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: const TextStyle(color: AdminColors.success, fontWeight: FontWeight.w800, fontSize: 12)),
  );
}

/// Hero greeting card
class DashboardHeroCard extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onReportsTap;
  final VoidCallback onProfileTap;
  const DashboardHeroCard({super.key, required this.unreadCount, required this.onReportsTap, required this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        image: const DecorationImage(
          image: AssetImage('assets/images/admin_purple.png'),
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
        ),
        boxShadow: [BoxShadow(color: AdminColors.primary.withOpacity(0.28), blurRadius: 30, offset: const Offset(0, 14))],
      ),
      child: Stack(children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                const Color(0xFF6A3CEF).withOpacity(0.97),
                const Color(0xFF8A5BFF).withOpacity(0.88),
                const Color(0xFF4B1FD6).withOpacity(0.50),
              ],
            ),
          ),
        ),
        const Positioned(right: -36, top: -36, child: DashboardGlow(130)),
        const Positioned(left: -50, bottom: -50, child: DashboardGlow(140, opacity: 0.09)),
        Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                const Text('Welcome back,',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: AdminColors.white, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AdminColors.success)),
                    const SizedBox(width: 5),
                    const Text('Active', style: TextStyle(color: AdminColors.success, fontWeight: FontWeight.w800, fontSize: 12)),
                  ]),
                ),
              ]),
              const SizedBox(height: 6),
              const Text('Admin User 👋',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: -.6)),
              const SizedBox(height: 8),
              const Text('Monitor applicants, plots and\npayments with real-time insights',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13, height: 1.45)),
              const SizedBox(height: 18),
              IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DashboardWhiteButton(text: 'View Reports', icon: Icons.insert_chart_rounded, onTap: onReportsTap),
                    const SizedBox(height: 10),
                    DashboardGlassButton(text: 'My Profile', icon: Icons.person_rounded, onTap: onProfileTap),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ]),
    );
  }
}

class DashboardWhiteButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  const DashboardWhiteButton({super.key, required this.text, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: AdminColors.white,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: AdminColors.primary, size: 18),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w800, fontSize: 14)),
        ]),
      ),
    ),
  );
}

class DashboardGlassButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  const DashboardGlassButton({super.key, required this.text, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withOpacity(0.15),
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.30)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
        ]),
      ),
    ),
  );
}

class DashboardStatsGrid extends StatelessWidget {
  final List<DashboardStat> stats;
  final void Function(String route) onTap;
  const DashboardStatsGrid({super.key, required this.stats, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < stats.length; i += 2) {
      final left  = stats[i];
      final right = i + 1 < stats.length ? stats[i + 1] : null;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: DashboardStatCard(stat: left,  onTap: () => onTap(left.route))),
              const SizedBox(width: 12),
              Expanded(
                child: right != null
                    ? DashboardStatCard(stat: right, onTap: () => onTap(right.route))
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
      if (i + 2 < stats.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }
}

class DashboardStatCard extends StatelessWidget {
  final DashboardStat stat;
  final VoidCallback onTap;
  const DashboardStatCard({super.key, required this.stat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38, width: 38,
            decoration: BoxDecoration(color: stat.color.withOpacity(0.13), borderRadius: BorderRadius.circular(12)),
            child: Icon(stat.icon, color: stat.color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(stat.title,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w700, fontSize: 11)),
          const SizedBox(height: 3),
          Text(stat.value,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -.5)),
        ],
      ),
    );
  }
}

class DashboardQuickActionsGrid extends StatelessWidget {
  final List<QuickAction> actions;
  final void Function(String route) onTap;
  const DashboardQuickActionsGrid({super.key, required this.actions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const cols = 4;
    final rows = <Widget>[];
    for (int i = 0; i < actions.length; i += cols) {
      final rowItems = actions.sublist(i, (i + cols).clamp(0, actions.length));
      rows.add(Row(
        children: List.generate(cols, (j) {
          if (j < rowItems.length) {
            final action = rowItems[j];
            final color = kDashboardActionColors[(i + j) % kDashboardActionColors.length];
            return Expanded(
              child: DashboardQuickItem(icon: action.icon, label: action.title, color: color, onTap: () => onTap(action.route)),
            );
          }
          return const Expanded(child: SizedBox());
        }),
      ));
      if (i + cols < actions.length) rows.add(const SizedBox(height: 16));
    }
    return Column(children: rows);
  }
}

class DashboardQuickItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const DashboardQuickItem({super.key, required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 58, width: 58,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: color.withOpacity(0.28), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 7),
          Text(label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w700, fontSize: 11, height: 1.2)),
        ],
      ),
    );
  }
}

class DashboardActivityTile extends StatelessWidget {
  final ActivityItem activity;
  final VoidCallback onTap;
  const DashboardActivityTile({super.key, required this.activity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Container(
          height: 44, width: 44,
          decoration: BoxDecoration(color: AdminColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
          child: Icon(activity.icon, color: AdminColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(activity.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 4),
          Text(activity.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 12, height: 1.3)),
        ])),
        const SizedBox(width: 8),
        Text(activity.time, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w800, fontSize: 11)),
      ]),
    );
  }
}

class DashboardNotificationCard extends StatelessWidget {
  final List notifications;
  final VoidCallback onOpen;
  final VoidCallback onRead;
  const DashboardNotificationCard({super.key, required this.notifications, required this.onOpen, required this.onRead});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            height: 44, width: 44,
            decoration: BoxDecoration(color: AdminColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.notifications_active_rounded, color: AdminColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(child: DashboardLabel(title: 'Notifications', subtitle: 'Priority admin alerts')),
          PopupMenuButton<String>(
            color: AdminColors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            onSelected: (v) => v == 'open' ? onOpen() : onRead(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'open', child: PopupMenuRow(icon: Icons.open_in_new_rounded, text: 'Open')),
              PopupMenuItem(value: 'read', child: PopupMenuRow(icon: Icons.done_all_rounded,    text: 'Mark Read')),
            ],
          ),
        ]),
        const SizedBox(height: 12),
        ...notifications.take(3).map((n) => ListTile(
          contentPadding: EdgeInsets.zero,
          onTap: () => showAdminSnack(context, n.title),
          leading: Icon(n.icon, color: AdminColors.primary),
          title: Text(n.title, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 14)),
          subtitle: Text(n.message, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 12)),
          trailing: n.unread ? const Icon(Icons.circle, size: 10, color: AdminColors.primary) : null,
        )),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: onRead, icon: const Icon(Icons.done_all_rounded), label: const Text('Mark Read'))),
          const SizedBox(width: 10),
          Expanded(child: FilledButton.icon(onPressed: onOpen, icon: const Icon(Icons.arrow_forward_rounded), label: const Text('Open'))),
        ]),
      ]),
    );
  }
}

class DashboardSheetRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const DashboardSheetRow({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          height: 40, width: 40,
          decoration: BoxDecoration(color: AdminColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: AdminColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 12)),
        ])),
        const Icon(Icons.arrow_forward_ios_rounded, color: AdminColors.greyText, size: 16),
      ]),
    ),
  );
}

class DashboardGlow extends StatelessWidget {
  final double size;
  final double opacity;
  const DashboardGlow(this.size, {super.key, this.opacity = 0.15});

  @override
  Widget build(BuildContext context) => Container(
    height: size, width: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(opacity)),
  );
}