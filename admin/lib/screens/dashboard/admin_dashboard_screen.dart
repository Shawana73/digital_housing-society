import 'package:flutter/material.dart';
import '../../widgets/admin_shell.dart';
import '../../app_routes.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/premium_widgets.dart';
import 'dashboard_viewmodel.dart';
import 'dashboard_widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminDashboardViewModel _viewModel = AdminDashboardViewModel();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_refresh);
    _viewModel.load();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DashboardLabel(title: 'Quick Create', subtitle: 'Choose an admin action'),
            const SizedBox(height: 10),
            DashboardSheetRow(icon: Icons.add_home_rounded,      title: 'Add Plot',         subtitle: 'Create new society plot',      onTap: () { Navigator.pop(context); _open(AdminRoutes.addPlot); }),
            DashboardSheetRow(icon: Icons.verified_user_rounded, title: 'Verify Applicant', subtitle: 'Open pending applicant files', onTap: () { Navigator.pop(context); _open(AdminRoutes.applicants); }),
            DashboardSheetRow(icon: Icons.payments_rounded,      title: 'Verify Payment',   subtitle: 'Approve payment receipts',     onTap: () { Navigator.pop(context); _open(AdminRoutes.payments); }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            DashboardHeroCard(
              unreadCount: _viewModel.unreadCount,
              onReportsTap: () => _open(AdminRoutes.reports),
              onProfileTap: () => _open(AdminRoutes.profile),
            ),
            const SizedBox(height: 24),
            Row(children: [
              const Expanded(child: DashboardLabel(title: 'Overview', subtitle: 'Live housing society metrics')),
              DashboardPillButton(label: 'Refresh', onTap: () { _viewModel.load(); showAdminSnack(context, 'Dashboard refreshed'); }),
            ]),
            const SizedBox(height: 12),
            DashboardStatsGrid(stats: _viewModel.stats, onTap: (r) => _open(r)),
            const SizedBox(height: 24),
            const DashboardLabel(title: 'Quick Actions', subtitle: 'Every module is one tap away'),
            const SizedBox(height: 14),
            DashboardQuickActionsGrid(actions: _viewModel.quickActions, onTap: (route) => _open(route)),
            const SizedBox(height: 24),
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
                          Text('Applicant Growth', style: TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -.3)),
                          SizedBox(height: 2),
                          Text('Monthly Verified Trend', style: TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 12)),
                        ],
                      ),
                    ),
                    DashboardGreenBadge(label: '↑ 32%'),
                  ]),
                  const SizedBox(height: 16),
                  SizedBox(height: 165, child: MiniLineChart(values: _viewModel.chartValues)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const DashboardLabel(title: 'Recent Activities', subtitle: 'Latest admin movement'),
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
                child: DashboardActivityTile(activity: a, onTap: () => showAdminSnack(context, a.title)),
              )),
            const SizedBox(height: 24),
            DashboardNotificationCard(
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