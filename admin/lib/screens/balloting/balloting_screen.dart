import 'package:flutter/material.dart';
import '../../app_routes.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_shell.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/premium_widgets.dart';
import 'balloting_viewmodel.dart';
import 'balloting_widgets.dart';

class BallotingScreen extends StatefulWidget {
  const BallotingScreen({super.key});

  @override
  State<BallotingScreen> createState() => _BallotingScreenState();
}

class _BallotingScreenState extends State<BallotingScreen> {
  final BallotingViewModel _viewModel = BallotingViewModel();
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

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Balloting',
      selectedIndex: 2,
      searchController: _searchController,
      searchHint: 'Search balloting sessions...',
      onSearchChanged: _viewModel.search,
      onSearchClear: () {
        _searchController.clear();
        _viewModel.clearSearch();
      },
      onFabTap: () => Navigator.pushNamed(context, AdminRoutes.results),
      fabLabel: 'Results',
      fabIcon: Icons.emoji_events_rounded,
      isLoading: _viewModel.isLoading,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        children: [
          const BallotingSectionLabel(text: 'Balloting Overview'),
          const SizedBox(height: 10),
          PremiumCard(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const Expanded(child: BallotingOverviewTile(icon: Icons.domain_rounded, label: 'Schemes', value: '05', color: AdminColors.primary)),
              BallotingVDivider(),
              const Expanded(child: BallotingOverviewTile(icon: Icons.hourglass_top_rounded, label: 'To Be Run', value: '02', color: AdminColors.warning)),
              BallotingVDivider(),
              const Expanded(child: BallotingOverviewTile(icon: Icons.check_circle_rounded, label: 'Completed', value: '02', color: AdminColors.success)),
              BallotingVDivider(),
              const Expanded(child: BallotingOverviewTile(icon: Icons.description_rounded, label: 'Results\nDeclared', value: '02', color: AdminColors.rejected)),
            ]),
          ),
          const SizedBox(height: 22),
          Row(children: [
            const Expanded(child: BallotingSectionLabel(text: 'Upcoming Ballotings')),
            GestureDetector(
              onTap: () => showAdminSnack(context, 'View all upcoming'),
              child: const Text('View All', style: TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          ]),
          const SizedBox(height: 12),
          BallotingSchemeCard(
            name: 'Green Valley Villas',
            size: '5 Marla Villa',
            eligibleApplicants: 1284,
            availablePlots: 120,
            date: '10 Jul 2026, 11:00 AM',
            status: 'To Be Run',
            statusColor: AdminColors.primary,
            imagePath: 'assets/images/Green_Valley_Villa.png',
            eligibleLabel: 'Eligible',
            plotsLabel: 'Plots',
            onStart: () => Navigator.pushNamed(context, AdminRoutes.ballotingProcessing, arguments: {
              'name': 'Green Valley Villas',
              'size': '5 Marla Villa',
            }),
          ),
          const SizedBox(height: 14),
          BallotingSchemeCard(
            name: 'Sunshine Residency',
            size: '10 Marla Villa',
            eligibleApplicants: 856,
            availablePlots: 80,
            date: '25 Jul 2026, 11:00 AM',
            status: 'To Be Run',
            statusColor: AdminColors.primary,
            imagePath: 'assets/images/Sunshine Residency.png',
            eligibleLabel: 'Eligible',
            plotsLabel: 'Plots',
            onStart: () => Navigator.pushNamed(context, AdminRoutes.ballotingProcessing, arguments: {
              'name': 'Sunshine Residency',
              'size': '10 Marla Villa',
            }),
          ),
          const SizedBox(height: 22),
          Row(children: [
            const Expanded(child: BallotingSectionLabel(text: 'Balloting History')),
            GestureDetector(
              onTap: () => showAdminSnack(context, 'View all history'),
              child: const Text('View All', style: TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          ]),
          const SizedBox(height: 12),
          BallotingHistoryCard(
            name: 'Royal Enclave',
            size: '5 Marla Villa',
            date: '15 Jun 2026, 11:00 AM',
            onTap: () => Navigator.pushNamed(context, AdminRoutes.results),
          ),
        ],
      ),
    );
  }
}