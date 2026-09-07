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
      onFabTap: () =>
          Navigator.pushNamed(
            context,
            AdminRoutes.results,
          ),
      fabLabel: 'Results',
      fabIcon:
      Icons.emoji_events_rounded,
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

                 BallotingVDivider(),

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

                BallotingVDivider(),

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

                BallotingVDivider(),

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
                  showAdminSnack(
                    context,
                    'Showing all upcoming ballotings',
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
            ...upcomingSchemes.map(
                  (scheme) {
                final eligibleApplicants =
                _viewModel
                    .getEligibleApplicantsForScheme(
                  scheme,
                );

                final availablePlots =
                _viewModel
                    .getAvailablePlotsForScheme(
                  scheme,
                );

                return Padding(
                  padding:
                  const EdgeInsets.only(
                    bottom: 14,
                  ),

                  child:
                  BallotingSchemeCard(
                    name: scheme.name,

                    size: scheme.size,

                    // Scheme-wise eligible applicants
                    eligibleApplicants:
                    eligibleApplicants,

                    // Scheme-wise available plots
                    availablePlots:
                    availablePlots,

                    date: _formatDate(
                      scheme.date.toDate(),
                    ),

                    status:
                    scheme.status,

                    statusColor:
                    AdminColors.primary,

                    imagePath:
                    scheme.imagePath,

                    eligibleLabel:
                    'Eligible',

                    plotsLabel:
                    'Plots',

                    onStart: () {
                      Navigator.pushNamed(
                        context,
                        AdminRoutes
                            .ballotingProcessing,

                        arguments: {
                          'name':
                          scheme.name,

                          'size':
                          scheme.size,

                          'schemeId':
                          scheme.documentId,
                        },
                      );
                    },
                  ),
                );
              },
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
                  showAdminSnack(
                    context,
                    'Showing all balloting history',
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
            ...completedSchemes.map(
                  (scheme) => Padding(
                padding:
                const EdgeInsets.only(
                  bottom: 14,
                ),

                child:
                BallotingHistoryCard(
                  name: scheme.name,

                  size: scheme.size,

                  date: _formatDate(
                    scheme.date.toDate(),
                  ),

                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AdminRoutes.results,
                      arguments: {
                        'schemeId':
                        scheme.documentId,

                        'schemeName':
                        scheme.name,
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}