import 'package:flutter/material.dart'; //flutter's core UI Toolkit (buttons, text, layout )
import '../app_routes.dart';
import '../models/admin_models.dart';
import '../theme/admin_theme.dart';
import '../viewmodels/admin_view_models.dart';
import '../widgets/admin_shell.dart';
import '../widgets/app_snack.dart';
import '../widgets/premium_widgets.dart';

// Colourful icon colours for Quick Action items
const List<Color> _kActionColors = [
  Color(0xFF7B4DFF), // violet
  Color(0xFF7B4DFF),
  Color(0xFF7B4DFF),
  Color(0xFF7B4DFF),
  Color(0xFF7B4DFF),
  Color(0xFF7B4DFF),
  Color(0xFF7B4DFF),
  Color(0xFF7B4DFF),
  /*Color(0xFF22C55E), // green
  Color(0xFFF59E0B), // amber
  Color(0xFF3B82F6), // blue
  Color(0xFFEC4899), // pink
  Color(0xFF8B5CF6), // purple
  Color(0xFF06B6D4), // cyan
  Color(0xFF10B981), // emerald*/
];

class AdminDashboardScreen extends StatefulWidget { //meaning this screen's content can change while it's on screen (e.g., after a network refresh). It just hands off the real work to _AdminDashboardScreenState.
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminDashboardViewModel _viewModel = AdminDashboardViewModel(); //holds all the dashboard's data (stats, activities, notifications) and knows how to load/refresh it.
  final TextEditingController _searchController = TextEditingController(); //tracks what the user types into the search bar.

  @override
  void initState() { //runs once when the screen first appears — it starts "listening" to the view model (so the UI rebuilds when data changes) and tells it to load data.
    super.initState();
    _viewModel.addListener(_refresh);
    _viewModel.load();
  }

  void _refresh() { //called whenever the view model's data changes; it re-draws the screen (setState).
    if (mounted) setState(() {});
  }

  @override
  void dispose() { //cleanup when the screen is closed — stops listening and frees memory. Important to avoid memory leaks.
    _viewModel.removeListener(_refresh);
    _viewModel.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _open(String route) => Navigator.pushNamed(context, route);

  void _openCreateSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AdminColors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Label(title: 'Quick Create', subtitle: 'Choose an admin action'),
            const SizedBox(height: 10),
            _SheetRow(icon: Icons.add_home_rounded,      title: 'Add Plot',         subtitle: 'Create new society plot',      onTap: () { Navigator.pop(context); _open(AdminRoutes.addPlot); }),
            _SheetRow(icon: Icons.verified_user_rounded, title: 'Verify Applicant', subtitle: 'Open pending applicant files', onTap: () { Navigator.pop(context); _open(AdminRoutes.applicants); }),
            _SheetRow(icon: Icons.payments_rounded,      title: 'Verify Payment',   subtitle: 'Approve payment receipts',     onTap: () { Navigator.pop(context); _open(AdminRoutes.payments); }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) { //This draws the actual UI, piece by piece, inside a scrollable ListView:
    return AdminShell(
      title: 'Admin Dashboard',
      selectedIndex: 0,
      searchController: _searchController,
      searchHint: 'Search activities, reports, applicants...',
      onSearchChanged: _viewModel.search,
      onSearchSubmitted: (v) => showAdminSnack(context, 'Searching "$v"'),
      onSearchClear: () { _searchController.clear(); _viewModel.clearSearch(); },
      onFabTap: _openCreateSheet,
      fabLabel: 'Action',
      fabIcon: Icons.add_rounded,
      isLoading: _viewModel.isLoading,
      body: RefreshIndicator(
        color: AdminColors.primary,
        onRefresh: _viewModel.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
          children: [

            // ── Hero greeting card ──────────────────────────────────────
            _HeroCard(
              unreadCount: _viewModel.unreadCount,
              onReportsTap: () => _open(AdminRoutes.reports),
              onProfileTap:  () => _open(AdminRoutes.profile),
            ),

            const SizedBox(height: 24),

            // ── Overview 2×2 grid ───────────────────────────────────────
            Row(children: [
              const Expanded(child: _Label(title: 'Overview', subtitle: 'Live housing society metrics')),
              _PillButton(
                label: 'Refresh',
                onTap: () { _viewModel.load(); showAdminSnack(context, 'Dashboard refreshed'); },
              ),
            ]),
            const SizedBox(height: 12),

            // Two-column grid that sizes itself to content — no fixed aspect ratio
            _StatsGrid(stats: _viewModel.stats, onTap: (r) => _open(r)),

            const SizedBox(height: 24),

            // ── Quick Actions ───────────────────────────────────────────
            const _Label(title: 'Quick Actions', subtitle: 'Every module is one tap away'),
            const SizedBox(height: 14),
            _QuickActionsGrid(
              actions: _viewModel.quickActions,
              onTap: (route) => _open(route),
            ),

            const SizedBox(height: 24),

            // ── Applicant Growth chart ──────────────────────────────────
            PremiumCard(
              onTap: () => _open(AdminRoutes.reports),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Applicant Growth',
                              style: TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -.3)),
                          SizedBox(height: 2),
                          Text('Monthly Verified Trend',
                              style: TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 12)),
                        ],
                      ),
                    ),
                    _GreenBadge(label: '↑ 32%'),
                  ]),
                  const SizedBox(height: 16),
                  SizedBox(height: 165, child: MiniLineChart(values: _viewModel.chartValues)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Recent Activities =>recent admin actions, or an "empty state" message if none match the search. ───────────────────────────────────────
            const _Label(title: 'Recent Activities', subtitle: 'Latest admin movement'),
            const SizedBox(height: 12),

            if (_viewModel.filteredActivities.isEmpty)
              EmptyState(
                icon: Icons.manage_search_rounded,
                title: 'No activity found',
                subtitle: 'Try another keyword or reset the search.',
                buttonText: 'Reset Search',
                onPressed: () { _searchController.clear(); _viewModel.clearSearch(); },
              )
            else
              ..._viewModel.filteredActivities.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ActivityTile(activity: a, onTap: () => showAdminSnack(context, a.title)),
              )),

            const SizedBox(height: 24),

            // ── Notifications ───────────────────────────────────────────
            _NotificationCard(
              notifications: _viewModel.notifications,
              onOpen: () => _open(AdminRoutes.notifications),
              onRead: () { _viewModel.markAllRead(); showAdminSnack(context, 'All marked as read'); },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared micro-widgets  are all reusable "building blocks" — each one is responsible for drawing one small visual piece (a button, a card, a label), keeping the main build() method clean and readable instead of one giant messy widget tree.
// ─────────────────────────────────────────────────────────────────────────────

/// Two-line section label.
class _Label extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Label({required this.title, required this.subtitle});

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
class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PillButton({required this.label, required this.onTap});

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
class _GreenBadge extends StatelessWidget {
  final String label;
  const _GreenBadge({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: AdminColors.success.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: const TextStyle(color: AdminColors.success, fontWeight: FontWeight.w800, fontSize: 12)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero greeting card
// ─────────────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onReportsTap;
  final VoidCallback onProfileTap;
  const _HeroCard({required this.unreadCount, required this.onReportsTap, required this.onProfileTap});

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
        // Purple gradient overlay
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
        // Decorative glow circles
        const Positioned(right: -36, top: -36, child: _Glow(130)),
        const Positioned(left: -50, bottom: -50, child: _Glow(140, opacity: 0.09)),

        Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row
              Row(children: [
                const Text('Welcome back,',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14)),
                const Spacer(),
                // Active badge
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
              // Both buttons same width — driven by the widest one (View Reports)
              IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _WhiteButton(text: 'View Reports', icon: Icons.insert_chart_rounded, onTap: onReportsTap),
                    const SizedBox(height: 10),
                    _GlassButton(text: 'My Profile', icon: Icons.person_rounded, onTap: onProfileTap),
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

/// "View Reports" — white background, purple icon & text, auto width
class _WhiteButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  const _WhiteButton({required this.text, required this.icon, required this.onTap});

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

/// "My Profile" — frosted glass, smaller, auto width
class _GlassButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  const _GlassButton({required this.text, required this.icon, required this.onTap});

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

// ─────────────────────────────────────────────────────────────────────────────
// Stats 2×2 grid — uses IntrinsicHeight rows so content never overflows
// ─────────────────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final List<DashboardStat> stats;
  final void Function(String route) onTap;
  const _StatsGrid({required this.stats, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Build rows of 2
    final rows = <Widget>[];
    for (int i = 0; i < stats.length; i += 2) {
      final left  = stats[i];
      final right = i + 1 < stats.length ? stats[i + 1] : null;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _StatCard(stat: left,  onTap: () => onTap(left.route))),
              const SizedBox(width: 12),
              Expanded(
                child: right != null
                    ? _StatCard(stat: right, onTap: () => onTap(right.route))
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

class _StatCard extends StatelessWidget {
  final DashboardStat stat;
  final VoidCallback onTap;
  const _StatCard({required this.stat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            height: 38, width: 38,
            decoration: BoxDecoration(
              color: stat.color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(stat.icon, color: stat.color, size: 20),
          ),
          const SizedBox(height: 10),
          // Label
          Text(stat.title,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w700, fontSize: 11)),
          const SizedBox(height: 3),
          // Value
          Text(stat.value,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -.5)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Actions — 4-column grid, full width, no gaps
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  final List<QuickAction> actions;
  final void Function(String route) onTap;
  const _QuickActionsGrid({required this.actions, required this.onTap});

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
            final color = _kActionColors[(i + j) % _kActionColors.length];
            return Expanded(
              child: _QuickItem(
                icon: action.icon,
                label: action.title,
                color: color,
                onTap: () => onTap(action.route),
              ),
            );
          }
          // empty filler to keep alignment
          return const Expanded(child: SizedBox());
        }),
      ));
      if (i + cols < actions.length) rows.add(const SizedBox(height: 16));
    }

    return Column(children: rows);
  }
}

class _QuickItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickItem({required this.icon, required this.label, required this.color, required this.onTap});

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
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w700, fontSize: 11, height: 1.2),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity tile — uses PremiumCard for full consistency
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityTile extends StatelessWidget {
  final ActivityItem activity;
  final VoidCallback onTap;
  const _ActivityTile({required this.activity, required this.onTap});

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
          Text(activity.title,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 4),
          Text(activity.subtitle,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 12, height: 1.3)),
        ])),
        const SizedBox(width: 8),
        Text(activity.time,
            style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w800, fontSize: 11)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification card — uses PremiumCard for full consistency
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final List notifications;
  final VoidCallback onOpen;
  final VoidCallback onRead;
  const _NotificationCard({required this.notifications, required this.onOpen, required this.onRead});

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
          const Expanded(child: _Label(title: 'Notifications', subtitle: 'Priority admin alerts')),
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
          title: Text(n.title,
              style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 14)),
          subtitle: Text(n.message, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 12)),
          trailing: n.unread ? const Icon(Icons.circle, size: 10, color: AdminColors.primary) : null,
        )),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: onRead,
            icon: const Icon(Icons.done_all_rounded),
            label: const Text('Mark Read'),
          )),
          const SizedBox(width: 10),
          Expanded(child: FilledButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Open'),
          )),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet row (bottom sheet actions)
// ─────────────────────────────────────────────────────────────────────────────

class _SheetRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SheetRow({required this.icon, required this.title, required this.subtitle, required this.onTap});

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
          Text(title,    style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 12)),
        ])),
        const Icon(Icons.arrow_forward_ios_rounded, color: AdminColors.greyText, size: 16),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Decorative helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Glow extends StatelessWidget {
  final double size;
  final double opacity;
  const _Glow(this.size, {this.opacity = 0.15});

  @override
  Widget build(BuildContext context) => Container(
    height: size, width: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(opacity)),
  );
}