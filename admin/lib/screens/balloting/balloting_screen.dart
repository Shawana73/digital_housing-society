import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_shell.dart';
import '../../widgets/premium_widgets.dart';
import '../../models/scheme_model.dart';
import 'add_scheme_screen.dart';
import 'balloting_viewmodel.dart';
import 'balloting_widgets.dart';

class BallotingScreen extends StatefulWidget {
  const BallotingScreen({super.key});

  @override
  State<BallotingScreen> createState() =>
      _BallotingScreenState();
}

class _BallotingScreenState
    extends State<BallotingScreen> {
  final BallotingViewModel _viewModel =
  BallotingViewModel();

  final TextEditingController _searchController =
  TextEditingController();

  @override
  void initState() {
    super.initState();

    _viewModel.addListener(_refresh);
    _viewModel.load();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_refresh);
    _viewModel.dispose();
    _searchController.dispose();

    super.dispose();
  }

  String _formatDate(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;

    final minute =
    date.minute.toString().padLeft(2, '0');

    final period =
    date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day.toString().padLeft(2, '0')} '
        '${_monthName(date.month)} ${date.year}, '
        '$hour:$minute $period';
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }

  Widget _buildUpcomingCard(SchemeModel scheme) {
    final eligibleApplicants =
    _viewModel.getEligibleApplicantsForScheme(scheme);

    final availablePlots =
    _viewModel.getAvailablePlotsForScheme(scheme);

    return BallotingSchemeCard(
      name: scheme.name,
      size: scheme.size,
      eligibleApplicants: eligibleApplicants,
      availablePlots: availablePlots,
      date: _formatDate(scheme.date.toDate()),
      status: scheme.status,
      statusColor: AdminColors.primary,
      imagePath: scheme.imagePath,
      eligibleLabel: 'Eligible',
      plotsLabel: 'Plots',
      onStart: () async {
        // FIX (bug): previously this was a fire-and-forget push, so when
        // the admin returned from the processing screen (after
        // completing a balloting, which updates the scheme's status in
        // Firestore), this screen's already-in-memory list was never
        // refreshed — the scheme stayed showing under "Upcoming" even
        // though Firestore already had it marked 'Completed'. Awaiting
        // the navigation and reloading afterward keeps the list in sync.
        await Navigator.pushNamed(
          context,
          AdminRoutes.ballotingProcessing,
          arguments: {
            'name': scheme.name,
            'size': scheme.size,
            'schemeId': scheme.documentId,
            'schemeDate': scheme.date,
          },
        );
        if (!mounted) return;
        _viewModel.load();
      },
    );
  }

  Widget _buildHistoryCard(SchemeModel scheme) {
    return BallotingHistoryCard(
      name: scheme.name,
      size: scheme.size,
      date: _formatDate(scheme.date.toDate()),
      onTap: () {
        Navigator.pushNamed(
          context,
          AdminRoutes.results,
          arguments: {
            'schemeId': scheme.documentId,
            'schemeName': scheme.name,
          },
        );
      },
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.rejected.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.rejected.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AdminColors.rejected, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AdminColors.rejected, fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
          ),
          TextButton(
            onPressed: _viewModel.load,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final upcomingSchemes =
        _viewModel.upcomingSchemes;

    final completedSchemes =
        _viewModel.completedSchemes;

    return AdminShell(
      title: 'Balloting',
      selectedIndex: 2,
      searchController: _searchController,
      searchHint:
      'Search balloting sessions...',
      onSearchChanged: _viewModel.search,
      onSearchClear: () {
        _searchController.clear();
        _viewModel.clearSearch();
      },
      // FIX (missing feature): FAB now opens Add New Scheme instead of
      // the combined Results view. Results are still reachable per-scheme
      // via each completed scheme's History card.
      onFabTap: () async {
        final added = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const AddSchemeScreen()),
        );
        if (added == true) {
          _viewModel.load();
        }
      },
      fabLabel: 'Add Scheme',
      fabIcon:
      Icons.add_home_work_rounded,
      isLoading: _viewModel.isLoading,

      body: ListView(
        physics:
        const BouncingScrollPhysics(),

        padding:
        const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          120,
        ),

        children: [
          if (_viewModel.errorMessage != null)
            _buildErrorBanner(_viewModel.errorMessage!),

          // =====================================================
          // BALLOTING OVERVIEW
          // =====================================================

          const BallotingSectionLabel(
            text: 'Balloting Overview',
          ),

          const SizedBox(height: 10),

          PremiumCard(
            padding:
            const EdgeInsets.all(16),

            child: Row(
              children: [
                Expanded(
                  child:
                  BallotingOverviewTile(
                    icon:
                    Icons.domain_rounded,
                    label: 'Schemes',
                    value:
                    '${_viewModel.totalSchemes}',
                    color:
                    AdminColors.primary,
                  ),
                ),

                const BallotingVDivider(),

                Expanded(
                  child:
                  BallotingOverviewTile(
                    icon:
                    Icons.hourglass_top_rounded,
                    label: 'To Be Run',
                    value:
                    '${_viewModel.upcomingCount}',
                    color:
                    AdminColors.warning,
                  ),
                ),

                const BallotingVDivider(),

                Expanded(
                  child:
                  BallotingOverviewTile(
                    icon:
                    Icons.check_circle_rounded,
                    label: 'Completed',
                    value:
                    '${_viewModel.completedCount}',
                    color:
                    AdminColors.success,
                  ),
                ),

                const BallotingVDivider(),

                Expanded(
                  child:
                  BallotingOverviewTile(
                    icon:
                    Icons.description_rounded,
                    label:
                    'Results\nDeclared',
                    value:
                    '${_viewModel.resultsDeclaredCount}',
                    color:
                    AdminColors.rejected,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // =====================================================
          // UPCOMING BALLOTINGS
          // =====================================================

          Row(
            children: [
              const Expanded(
                child:
                BallotingSectionLabel(
                  text:
                  'Upcoming Ballotings',
                ),
              ),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SchemeListScreen(
                        title: 'All Upcoming Ballotings',
                        cards: upcomingSchemes
                            .map(_buildUpcomingCard)
                            .toList(),
                      ),
                    ),
                  );
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color:
                    AdminColors.primary,
                    fontWeight:
                    FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (upcomingSchemes.isEmpty)
            const PremiumCard(
              padding:
              EdgeInsets.all(18),
              child: Center(
                child: Text(
                  'No upcoming ballotings found.',
                  style: TextStyle(
                    color:
                    AdminColors.greyText,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            ...upcomingSchemes.take(5).map(
                  (scheme) => Padding(
                padding:
                const EdgeInsets.only(
                  bottom: 14,
                ),
                child: _buildUpcomingCard(scheme),
              ),
            ),

          const SizedBox(height: 8),

          // =====================================================
          // BALLOTING HISTORY
          // =====================================================

          Row(
            children: [
              const Expanded(
                child:
                BallotingSectionLabel(
                  text:
                  'Balloting History',
                ),
              ),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SchemeListScreen(
                        title: 'All Balloting History',
                        cards: completedSchemes
                            .map(_buildHistoryCard)
                            .toList(),
                      ),
                    ),
                  );
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color:
                    AdminColors.primary,
                    fontWeight:
                    FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (completedSchemes.isEmpty)
            const PremiumCard(
              padding:
              EdgeInsets.all(18),
              child: Center(
                child: Text(
                  'No completed ballotings found.',
                  style: TextStyle(
                    color:
                    AdminColors.greyText,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            ...completedSchemes.take(5).map(
                  (scheme) => Padding(
                padding:
                const EdgeInsets.only(
                  bottom: 14,
                ),
                child: _buildHistoryCard(scheme),
              ),
            ),
        ],
      ),
    );
  }
}