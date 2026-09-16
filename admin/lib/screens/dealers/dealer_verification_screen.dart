import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_shell.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/premium_widgets.dart';
import 'dealer_viewmodel.dart';
import 'dealer_widgets.dart';

class DealerVerificationScreen extends StatefulWidget {
  const DealerVerificationScreen({super.key});

  @override
  State<DealerVerificationScreen> createState() => _DealerVerificationScreenState();
}

class _DealerVerificationScreenState extends State<DealerVerificationScreen> {
  final DealerVerificationViewModel _viewModel = DealerVerificationViewModel();
  final TextEditingController _searchController = TextEditingController();

  /// Stores only the verified/rejected dealers that the admin has opened for review.
  final Set<String> _reviewingDealers = {};

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

  void _showProfile(Dealer dealer) {
    showDialog(
      context: context,
      builder: (context) => DealerProfileDialog(dealer: dealer),
    );
  }

  void _openReview(Dealer dealer) {
    setState(() {
      _reviewingDealers.add(dealer.id);
    });
  }

  Future<void> _approve(Dealer dealer) async {
    await _viewModel.approve(dealer);

    if (!mounted) return;

    setState(() {
      _reviewingDealers.remove(dealer.id);
    });

    showAdminSnack(context, '${dealer.name} approved');
  }

  Future<void> _reject(Dealer dealer) async {
    await _viewModel.reject(dealer);

    if (!mounted) return;

    setState(() {
      _reviewingDealers.remove(dealer.id);
    });

    showAdminSnack(context, '${dealer.name} rejected');
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Dealers',
      selectedIndex: 0,
      searchController: _searchController,
      searchHint: 'Search dealers, CNIC, phone...',
      onSearchChanged: _viewModel.search,
      onSearchClear: () {
        _searchController.clear();
        _viewModel.clearSearch();
      },
      onFabTap: () => showAdminSnack(context, 'Invite dealer clicked'),
      fabLabel: 'Invite',
      fabIcon: Icons.person_add_rounded,
      isLoading: _viewModel.isLoading,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        children: [
          DealerStatsBanner(dealers: _viewModel.dealers),
          FilterTabs(
            filters: _viewModel.filters,
            selected: _viewModel.selectedFilter,
            onSelected: _viewModel.setFilter,
          ),
          const SizedBox(height: 14),
          if (_viewModel.filteredDealers.isEmpty)
            EmptyState(
              icon: Icons.real_estate_agent_outlined,
              title: 'No dealers found',
              subtitle: 'No dealer matches current filters.',
              buttonText: 'Reset',
              onPressed: () {
                _searchController.clear();
                _viewModel.clearSearch();
                _viewModel.setFilter('All');
              },
            )
          else
            ..._viewModel.filteredDealers.map((dealer) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: DealerCard(
                dealer: dealer,
                isReviewing: _reviewingDealers.contains(dealer.id),
                onApprove: () => _approve(dealer),
                onReject: () => _reject(dealer),
                onOpenReview: () => _openReview(dealer),
                onView: () => _showProfile(dealer),
              ),
            )),
        ],
      ),
    );
  }
}