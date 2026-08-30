import 'package:flutter/material.dart';
import '../../app_routes.dart';
import '../../models/admin_models.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_shell.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/premium_widgets.dart';
import 'applicant_viewmodel.dart';
import 'applicant_widgets.dart';

class ApplicantVerificationScreen extends StatefulWidget {
  const ApplicantVerificationScreen({super.key});

  @override
  State<ApplicantVerificationScreen> createState() => _ApplicantVerificationScreenState();
}

class _ApplicantVerificationScreenState extends State<ApplicantVerificationScreen> {
  final ApplicantVerificationViewModel _viewModel = ApplicantVerificationViewModel();
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

  Future<void> _confirmStatus(Applicant applicant, bool approve) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminColors.radius)),
        title: Text(approve ? 'Approve Applicant?' : 'Reject Applicant?',
            style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900)),
        content: Text(
          '${applicant.name} will be marked as ${approve ? 'verified' : 'rejected'}.',
          style: const TextStyle(color: AdminColors.greyText),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(approve ? 'Approve' : 'Reject')),
        ],
      ),
    );
    if (result == true) {
      if (approve) {
        await _viewModel.approve(applicant);
      } else {
        await _viewModel.reject(applicant);
      }
      if (mounted) {
        showAdminSnack(context, '${applicant.name} ${approve ? 'approved' : 'rejected'}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Applicants',
      selectedIndex: 1,
      searchController: _searchController,
      searchHint: 'Search applicants, CNIC, phone...',
      onSearchChanged: _viewModel.search,
      onSearchClear: () {
        _searchController.clear();
        _viewModel.clearSearch();
      },
      isLoading: _viewModel.isLoading,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        children: [
          ApplicantStatsBanner(applicants: _viewModel.applicants),
          const SizedBox(height: 22),
          Row(children: [
            const Expanded(
              child: Text('Applicants',
                  style: TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -.4)),
            ),
            GestureDetector(
              onTap: () => showAdminSnack(context, 'Sort clicked'),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Sort', style: TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w800, fontSize: 13)),
                SizedBox(width: 4),
                Icon(Icons.swap_vert_rounded, color: AdminColors.primary, size: 18),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          FilterTabs(filters: _viewModel.filters, selected: _viewModel.selectedFilter, onSelected: _viewModel.setFilter),
          const SizedBox(height: 14),
          if (_viewModel.filteredApplicants.isEmpty)
            EmptyState(
              icon: Icons.person_search_rounded,
              title: 'No applicants found',
              subtitle: 'No applicant matches this search or filter.',
              buttonText: 'Reset',
              onPressed: () {
                _searchController.clear();
                _viewModel.clearSearch();
                _viewModel.setFilter('All');
              },
            )
          else
            ..._viewModel.filteredApplicants.map((applicant) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ApplicantRow(
                applicant: applicant,
                onApprove: () => _confirmStatus(applicant, true),
                onReject: () => _confirmStatus(applicant, false),
                onTap: () => Navigator.pushNamed(context, AdminRoutes.applicantDetails, arguments: applicant),
              ),
            )),
        ],
      ),
    );
  }
}