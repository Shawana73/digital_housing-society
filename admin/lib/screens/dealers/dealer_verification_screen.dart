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
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
          child: PremiumCard(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: AdminColors.primary.withValues(alpha: 0.12),
              child: const Icon(
                Icons.real_estate_agent_rounded,
                color: AdminColors.primary,
                size: 34,
              ),
            ),            const SizedBox(height: 12),
            Text(dealer.name, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 20)),
            const SizedBox(height: 8),
            StatusPill(label: dealer.status.label, color: dealer.status.color),
            const SizedBox(height: 14),
            InfoRow(
              icon: Icons.person_rounded,
              label: 'Full Name',
              value: dealer.name,
            ),
            InfoRow(
              icon: Icons.credit_card_rounded,
              label: 'CNIC',
              value: dealer.cnic,
            ),
            InfoRow(
              icon: Icons.email_rounded,
              label: 'Email',
              value: dealer.email,
            ),
            InfoRow(
              icon: Icons.phone_rounded,
              label: 'Phone',
              value: dealer.phone,
            ),
            InfoRow(
              icon: Icons.business_rounded,
              label: 'Company / Agency',
              value: dealer.agency,
            ),
            InfoRow(
              icon: Icons.business_center_rounded,
              label: 'Business Type',
              value: dealer.businessType,
            ),
            InfoRow(
              icon: Icons.category_rounded,
              label: 'Specialization',
              value: dealer.specialization,
            ),
            InfoRow(
              icon: Icons.receipt_long_rounded,
              label: 'NTN Number',
              value: dealer.ntnNumber,
            ),
            InfoRow(
              icon: Icons.work_history_rounded,
              label: 'Years in Business',
              value: dealer.yearsInBusiness,
            ),
            InfoRow(
              icon: Icons.location_city_rounded,
              label: 'City',
              value: dealer.city,
            ),
            InfoRow(
              icon: Icons.map_rounded,
              label: 'Area',
              value: dealer.area,
            ),
            InfoRow(
              icon: Icons.location_on_rounded,
              label: 'Business Address',
              value: dealer.businessAddress,
            ),
            InfoRow(
              icon: Icons.store_rounded,
              label: 'Office Address',
              value: dealer.officeAddress,
            ),
            InfoRow(
              icon: Icons.phone_in_talk_rounded,
              label: 'Office Phone',
              value: dealer.officePhone,
            ),
            const SizedBox(height: 14),
                      FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close Profile'),
                      ),
                    ],
                ),
              ),
            ),
          ),
      ),
    );
  }

  Future<void> _approve(Dealer dealer) async {
    await _viewModel.approve(dealer);

    if (!mounted) return;

    showAdminSnack(context, '${dealer.name} approved');
  }

  Future<void> _reject(Dealer dealer) async {
    await _viewModel.reject(dealer);

    if (!mounted) return;

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
      body: Column(children: [
        FilterTabs(filters: _viewModel.filters, selected: _viewModel.selectedFilter, onSelected: _viewModel.setFilter),
        const SizedBox(height: 12),
        Expanded(
          child: _viewModel.filteredDealers.isEmpty
              ? EmptyState(
              icon: Icons.real_estate_agent_outlined,
              title: 'No dealers found',
              subtitle: 'No dealer matches current filters.',
              buttonText: 'Reset',
              onPressed: () {
                _searchController.clear();
                _viewModel.clearSearch();
                _viewModel.setFilter('All');
              })
              : ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            itemCount: _viewModel.filteredDealers.length,
            itemBuilder: (context, index) {
              final dealer = _viewModel.filteredDealers[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: DealerCard(dealer: dealer, onApprove: () => _approve(dealer), onReject: () => _reject(dealer), onView: () => _showProfile(dealer)),
              );
            },
          ),
        ),
      ]),
    );
  }
}