import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/admin_shell.dart';
import '../../app_routes.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/premium_widgets.dart';
import '../../models/admin_models.dart';
import '../applicant_details/applicant_details_screen.dart';
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

  void _onSearchResultTap(DashboardSearchResult result) {
    switch (result.type) {
      case DashboardSearchResultType.screen:
        if (result.route != null) _open(result.route!);
        break;
      case DashboardSearchResultType.applicant:
        final data = result.doc!.data();
        final applicant = Applicant(
          id: (data['uid'] ?? result.doc!.id).toString(),
          name: (data['fullName'] ?? 'Unknown').toString(),
          cnic: (data['cnic'] ?? '').toString(),
          phone: (data['phone'] ?? '').toString(),
          email: (data['email'] ?? '').toString(),
          address: (data['address'] ?? '').toString(),
          occupation: '',
          avatarLetters: (data['fullName'] ?? 'NA').toString().isNotEmpty
              ? (data['fullName'] ?? 'NA').toString().substring(0, 1).toUpperCase()
              : 'NA',
          documents: const [],
          status: (data['profileStatus']?.toString().toLowerCase() == 'verified')
              ? VerificationStatus.verified
              : (data['profileStatus']?.toString().toLowerCase() == 'rejected')
              ? VerificationStatus.rejected
              : VerificationStatus.pending,
        );
        Navigator.push(context, MaterialPageRoute(builder: (_) => ApplicantDetailsScreen(applicant: applicant)));
        break;
      case DashboardSearchResultType.plot:
        _open(AdminRoutes.plots);
        break;
    }
  }

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
      onRefresh: _viewModel.load,
      body: RefreshIndicator(
        color: AdminColors.primary,
        onRefresh: _viewModel.load,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              children: [
                if (_viewModel.hasError)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.red),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('Could not load latest data. Pull down to retry.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 13))),
                    ]),
                  ),
                if (_viewModel.query.isNotEmpty) ...[
                  const DashboardLabel(title: 'Search Results', subtitle: 'Matching screens, applicants & plots'),
                  const SizedBox(height: 12),
                  DashboardSearchResultsList(results: _viewModel.searchResults, onResultTap: _onSearchResultTap),
                  const SizedBox(height: 24),
                ],
                DashboardHeroCard(
                  unreadCount: _viewModel.unreadCount,
                  adminName: _viewModel.adminName,
                  onReportsTap: () => _open(AdminRoutes.reports),
                  onProfileTap: () => _open(AdminRoutes.profile),
                ),
                const SizedBox(height: 24),
                Row(children: [
                  const Expanded(child: DashboardLabel(title: 'Overview', subtitle: 'Live housing society metrics')),
                  DashboardPillButton(label: 'Refresh', onTap: () { _viewModel.load(); showAdminSnack(context, 'Dashboard refreshed'); }),
                ]),
                const SizedBox(height: 14),
                DashboardMiniStatsRow(stats: _viewModel.stats, onTap: (r) => _open(r)),
                const SizedBox(height: 24),

                if (isWide)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: DashboardOverviewCard(
                            period: _viewModel.chartPeriod,
                            onPeriodChanged: _viewModel.setChartPeriod,
                            chartValues: _viewModel.chartValues,
                            totalThisPeriod: _viewModel.totalThisPeriod,
                            peakLabel: _viewModel.peakLabel,
                            peakValue: _viewModel.peakValue,
                            averageValue: _viewModel.averageValue,
                            onTap: () => _open(AdminRoutes.reports),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DashboardBreakdownDonutCard(
                            title: 'Application Status',
                            subtitle: 'Current breakdown',
                            total: _viewModel.totalApplicants,
                            slices: _viewModel.applicationStatusSlices,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  DashboardOverviewCard(
                    period: _viewModel.chartPeriod,
                    onPeriodChanged: _viewModel.setChartPeriod,
                    chartValues: _viewModel.chartValues,
                    totalThisPeriod: _viewModel.totalThisPeriod,
                    peakLabel: _viewModel.peakLabel,
                    peakValue: _viewModel.peakValue,
                    averageValue: _viewModel.averageValue,
                    onTap: () => _open(AdminRoutes.reports),
                  ),
                  const SizedBox(height: 16),
                  DashboardBreakdownDonutCard(
                    title: 'Application Status',
                    subtitle: 'Current breakdown',
                    total: _viewModel.totalApplicants,
                    slices: _viewModel.applicationStatusSlices,
                  ),
                ],
                const SizedBox(height: 24),

                DashboardProgressListCard(
                  title: 'Plot Availability',
                  subtitle: 'Total inventory: ${_viewModel.totalPlots} plots',
                  total: _viewModel.totalPlots,
                  totalLabel: 'Total Plots',
                  totalIcon: Icons.location_on_rounded,
                  slices: _viewModel.plotSlices,
                ),
                const SizedBox(height: 24),
                Row(children: [
                  const Expanded(child: DashboardLabel(title: 'Recent Activities', subtitle: 'Latest admin movement')),
                  DashboardPillButton(label: 'View All', onTap: () => _open(AdminRoutes.reports)),
                ]),
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
            );
          },
        ),
      ),
    );
  }
}