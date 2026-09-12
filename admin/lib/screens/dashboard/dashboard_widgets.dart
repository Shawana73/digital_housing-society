import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/premium_widgets.dart';
import '../../widgets/app_snack.dart';
import '../../models/admin_models.dart';



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
  final String adminName;
  final VoidCallback onReportsTap;
  final VoidCallback onProfileTap;
  const DashboardHeroCard({super.key, required this.unreadCount, required this.adminName, required this.onReportsTap, required this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: AdminColors.primary.withOpacity(0.35), blurRadius: 40, spreadRadius: -4, offset: const Offset(0, 18)),
          BoxShadow(color: AdminColors.primary.withOpacity(0.18), blurRadius: 70, spreadRadius: 4, offset: const Offset(0, 26)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/Green_Valley_Villa.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  const Color(0xFF4B1FD6).withOpacity(0.93),
                  const Color(0xFF6A3CEF).withOpacity(0.85),
                  Colors.black.withOpacity(0.45),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.20),
                    Colors.transparent,
                    Colors.black.withOpacity(0.10),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF4B1FD6).withOpacity(0.22),
                  ],
                  stops: const [0.6, 1.0],
                ),
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
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 1))],
                      )),
                  const Spacer(),
                  if (unreadCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.notifications_rounded, color: Colors.white, size: 13),
                        const SizedBox(width: 4),
                        Text('$unreadCount new', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                      ]),
                    ),
                    const SizedBox(width: 8),
                  ],
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
                Text('$adminName ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                      letterSpacing: -.6,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 2))],
                    )),
                const SizedBox(height: 8),
                const Text('Monitor applicants, plots and\npayments with real-time insights',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      height: 1.45,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 1))],
                    )),
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
      ),
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

// ============================================================
// Colourful mini stat cards (Total Applicants / Plots / Payments)
// ============================================================

class DashboardMiniStatsRow extends StatelessWidget {
  final List<DashboardStat> stats;
  final void Function(String route) onTap;
  const DashboardMiniStatsRow({super.key, required this.stats, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final columns = width >= 1100 ? 5 : (width >= 800 ? 3 : (width >= 500 ? 2 : 1));

      if (columns == 1) {
        return Column(
          children: [
            for (int i = 0; i < stats.length; i++) ...[
              if (i != 0) const SizedBox(height: 10),
              DashboardMiniStatCard(stat: stats[i], onTap: () => onTap(stats[i].route)),
            ],
          ],
        );
      }

      const spacing = 10.0;
      final rawWidth = (width - spacing * (columns - 1)) / columns;
      final itemWidth = rawWidth.clamp(0, 190).toDouble();

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: stats
            .map((s) => SizedBox(
          width: itemWidth,
          child: DashboardMiniStatCard(stat: s, onTap: () => onTap(s.route)),
        ))
            .toList(),
      );
    });
  }
}
class DashboardMiniStatCard extends StatelessWidget {
  final DashboardStat stat;
  final VoidCallback onTap;
  const DashboardMiniStatCard({super.key, required this.stat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Container(
            height: 32, width: 32,
            decoration: BoxDecoration(color: stat.color, borderRadius: BorderRadius.circular(10)),
            child: Icon(stat.icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(stat.value,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: -.3)),
                const SizedBox(height: 1),
                Text(stat.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w700, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Application Overview chart card with period tabs
// ============================================================

enum ChartPeriod { today, week, month, year }

extension ChartPeriodLabel on ChartPeriod {
  String get label {
    switch (this) {
      case ChartPeriod.today:
        return 'Today';
      case ChartPeriod.week:
        return 'This Week';
      case ChartPeriod.month:
        return 'This Month';
      case ChartPeriod.year:
        return 'This Year';
    }
  }
}

class DashboardPeriodTabs extends StatelessWidget {
  final ChartPeriod selected;
  final ValueChanged<ChartPeriod> onChanged;
  const DashboardPeriodTabs({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: AdminColors.background, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: ChartPeriod.values.map((p) {
            final isSelected = p == selected;
            return GestureDetector(
              onTap: () => onChanged(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected ? AdminColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  p.label,
                  style: TextStyle(
                    color: isSelected ? AdminColors.white : AdminColors.greyText,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class DashboardOverviewCard extends StatelessWidget {
  final ChartPeriod period;
  final ValueChanged<ChartPeriod> onPeriodChanged;
  final List<double> chartValues;
  final int totalThisPeriod;
  final String peakLabel;
  final double peakValue;
  final double averageValue;
  final VoidCallback onTap;
  const DashboardOverviewCard({
    super.key,
    required this.period,
    required this.onPeriodChanged,
    required this.chartValues,
    required this.totalThisPeriod,
    required this.peakLabel,
    required this.peakValue,
    required this.averageValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DashboardLabel(title: 'Application Overview', subtitle: 'Applications submitted over time'),
          const SizedBox(height: 14),
          DashboardPeriodTabs(selected: period, onChanged: onPeriodChanged),
          const SizedBox(height: 18),
          SizedBox(height: 165, child: MiniLineChart(values: chartValues)),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _OverviewFooterStat(label: 'Total this period', value: '$totalThisPeriod')),
              Expanded(child: _OverviewFooterStat(label: 'Peak', value: peakLabel)),
              Expanded(child: _OverviewFooterStat(label: 'Average', value: averageValue.toStringAsFixed(0))),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewFooterStat extends StatelessWidget {
  final String label;
  final String value;
  const _OverviewFooterStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 11)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 15)),
    ],
  );
}

// ============================================================
// Reusable breakdown donut card (Application Status)
// ============================================================

class BreakdownSlice {
  final String label;
  final int value;
  final double percent; // 0..1
  final Color color;
  const BreakdownSlice({required this.label, required this.value, required this.percent, required this.color});
}

class DashboardBreakdownDonutCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int total;
  final List<BreakdownSlice> slices;
  final String emptyMessage;
  const DashboardBreakdownDonutCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.total,
    required this.slices,
    this.emptyMessage = 'No data yet',
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardLabel(title: title, subtitle: subtitle),
          const SizedBox(height: 18),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(emptyMessage, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            )
          else ...[
            Center(
              child: SizedBox(
                height: 170, width: 170,
                child: CustomPaint(
                  painter: _DonutPainter(slices: slices),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$total', style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 24)),
                        const Text('Total', style: TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            ...slices.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: s.color)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(s.label, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w700, fontSize: 13))),
                  Text('${s.value}', style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 13)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: s.color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                    child: Text('${(s.percent * 100).toStringAsFixed(0)}%', style: TextStyle(color: s.color, fontWeight: FontWeight.w800, fontSize: 11)),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<BreakdownSlice> slices;
  _DonutPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.16;
    final rect = Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth);
    double startAngle = -1.5708;
    for (final s in slices) {
      final sweep = s.percent * 6.28319;
      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.slices != slices;
}

// ============================================================
// Plot Availability progress-list card
// ============================================================

class DashboardProgressListCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int total;
  final String totalLabel;
  final IconData totalIcon;
  final List<BreakdownSlice> slices;
  const DashboardProgressListCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.total,
    required this.totalLabel,
    required this.totalIcon,
    required this.slices,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardLabel(title: title, subtitle: subtitle),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AdminColors.background, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(totalLabel, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('$total', style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 26)),
                    ],
                  ),
                ),
                Container(
                  height: 46, width: 46,
                  decoration: BoxDecoration(color: AdminColors.primary, borderRadius: BorderRadius.circular(14)),
                  child: Icon(totalIcon, color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ...slices.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: s.color)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s.label, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w700, fontSize: 13))),
                    Text('${s.value}', style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 13)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: s.color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                      child: Text('${(s.percent * 100).toStringAsFixed(0)}%', style: TextStyle(color: s.color, fontWeight: FontWeight.w800, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: s.percent.clamp(0.0, 1.0).toDouble(),
                    minHeight: 8,
                    backgroundColor: AdminColors.background,
                    valueColor: AlwaysStoppedAnimation(s.color),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ============================================================
// Global dashboard search
// ============================================================

enum DashboardSearchResultType { screen, applicant, plot }

class DashboardSearchResult {
  final String title;
  final String subtitle;
  final IconData icon;
  final DashboardSearchResultType type;
  final String? route;
  final QueryDocumentSnapshot<Map<String, dynamic>>? doc;

  const DashboardSearchResult({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.type,
    this.route,
    this.doc,
  });
}

class DashboardSearchResultsList extends StatelessWidget {
  final List<DashboardSearchResult> results;
  final void Function(DashboardSearchResult result) onResultTap;
  const DashboardSearchResultsList({super.key, required this.results, required this.onResultTap});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return PremiumCard(
        padding: const EdgeInsets.all(18),
        child: Row(children: [
          const Icon(Icons.search_off_rounded, color: AdminColors.greyText),
          const SizedBox(width: 10),
          const Expanded(child: Text('No matches found.', style: TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 13))),
        ]),
      );
    }
    return Column(
      children: results.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: PremiumCard(
          onTap: () => onResultTap(r),
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              height: 40, width: 40,
              decoration: BoxDecoration(color: AdminColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
              child: Icon(r.icon, color: AdminColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.title, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 14)),
              const SizedBox(height: 3),
              Text(r.subtitle, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 12)),
            ])),
            const Icon(Icons.arrow_forward_ios_rounded, color: AdminColors.greyText, size: 16),
          ]),
        ),
      )).toList(),
    );
  }
}