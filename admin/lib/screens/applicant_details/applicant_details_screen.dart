import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_shell.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/premium_widgets.dart';
import 'applicant_details_viewmodel.dart';
import 'applicant_details_widgets.dart';

class ApplicantDetailsScreen extends StatefulWidget {
  final Applicant applicant;
  const ApplicantDetailsScreen({super.key, required this.applicant});

  @override
  State<ApplicantDetailsScreen> createState() => _ApplicantDetailsScreenState();
}

class _ApplicantDetailsScreenState extends State<ApplicantDetailsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final ApplicantDetailsViewModel _viewModel = ApplicantDetailsViewModel();

  int _tabIndex = 0;
  final List<String> _tabs = const ['Documents', 'Personal Info', 'Payment Info', 'Activity Log'];

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_refresh);
    _viewModel.loadApplicant(widget.applicant);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_refresh);
    _viewModel.dispose();
    _searchController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _showFullImage(String title, IconData icon) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: PremiumCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(gradient: AdminColors.primaryGradient, borderRadius: BorderRadius.circular(24)),
                child: Icon(icon, size: 82, color: AdminColors.white),
              ),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 8),
              const Text('Dummy preview image for local UI testing.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close Preview')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setStatus(VerificationStatus status) async {
    try {
      await _viewModel.updateStatus(status);
      if (!mounted) return;
      showAdminSnack(context, '${widget.applicant.name} marked ${status.label}');
    } catch (e) {
      if (!mounted) return;
      showAdminSnack(context, 'Failed to update applicant status');
    }
  }

  void _saveNote() {
    if (_noteController.text.trim().isEmpty) return;
    showAdminSnack(context, 'Note saved');
    _noteController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final applicant = _viewModel.applicant;

    if (applicant == null) {
      return AdminShell(
        title: 'Applicant Details',
        selectedIndex: 1,
        searchController: _searchController,
        searchHint: 'Search inside applicant profile...',
        onSearchClear: () => _searchController.clear(),
        isLoading: _viewModel.isLoading,
        body: const Center(child: Text('Unable to load applicant details')),
      );
    }

    return AdminShell(
      title: 'Applicant Details',
      selectedIndex: 1,
      searchController: _searchController,
      searchHint: 'Search inside applicant profile...',
      onSearchClear: () => _searchController.clear(),
      onSearchSubmitted: (value) => showAdminSnack(context, 'Searching $value'),
      onFabTap: () => _showFullImage('Profile Picture', Icons.person_rounded),
      fabLabel: 'View Image',
      fabIcon: Icons.image_rounded,
      isLoading: _viewModel.isLoading,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 150),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AdminColors.white,
              borderRadius: BorderRadius.circular(AdminColors.radius),
              boxShadow: [BoxShadow(color: AdminColors.primary.withOpacity(0.18), blurRadius: 28, offset: const Offset(0, 12))],
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(children: [
                      Hero(
                        tag: 'applicant-${applicant.id}',
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: AdminColors.primary.withOpacity(0.12),
                          child: Text(applicant.avatarLetters,
                              style: const TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w900, fontSize: 20)),
                        ),
                      ),
                      if (applicant.status == VerificationStatus.verified)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            height: 20,
                            width: 20,
                            decoration: BoxDecoration(
                              color: AdminColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: AdminColors.white, width: 2),
                            ),
                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 12),
                          ),
                        ),
                    ]),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Text(applicant.name,
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -.4)),
                            ),
                            StatusPill(label: applicant.status.label, color: applicant.status.color),
                          ]),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(color: AdminColors.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(8)),
                            child: Text(applicant.id,
                                style: const TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w800, fontSize: 11)),
                          ),
                          const SizedBox(height: 10),
                          DetailsMiniLine(icon: Icons.email_rounded, text: applicant.email),
                          const SizedBox(height: 6),
                          DetailsMiniLine(icon: Icons.phone_rounded, text: applicant.phone),
                          const SizedBox(height: 6),
                          DetailsMiniLine(icon: Icons.location_on_rounded, text: applicant.address, maxLines: 2),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const DetailsDivider(),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      Row(children: [
                        Expanded(child: DetailsMetaTile(label: 'Applied On', value: _viewModel.appliedOn)),
                        const SizedBox(width: 12),
                        Expanded(child: DetailsMetaTile(label: 'Last Updated', value: _viewModel.profileCreatedOn)),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: DetailsMetaTile(label: 'Application Type', value: _viewModel.applicationType)),
                        const SizedBox(width: 12),
                        Expanded(child: DetailsMetaTile(label: 'Occupation', value: applicant.occupation)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          DetailsTabStrip(tabs: _tabs, selected: _tabIndex, onSelected: (i) => setState(() => _tabIndex = i)),
          const SizedBox(height: 16),
          _buildTabContent(applicant),
          const SizedBox(height: 18),
          PremiumCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Verification Notes',
                    style: TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 15)),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: AdminColors.primary,
                      child: Text('AK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              const Text('Ayesha Khan (Admin)',
                                  style: TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w800, fontSize: 12)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(color: AdminColors.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(8)),
                                child: const Text('Note',
                                    style: TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w700, fontSize: 9)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          const Text('28 Jun 2026, 11:30 AM',
                              style: TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 10)),
                          const SizedBox(height: 6),
                          const Text('All documents look good. Need to verify income proof.',
                              style: TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w600, fontSize: 12, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _noteController,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Add a note...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _saveNote,
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16)),
                    child: const Text('Save Note'),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _setStatus(VerificationStatus.rejected),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Reject Applicant'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminColors.rejected,
                  side: BorderSide(color: AdminColors.rejected.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _setStatus(VerificationStatus.verified),
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text('Verify Applicant'),
                style: FilledButton.styleFrom(backgroundColor: AdminColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildTabContent(Applicant applicant) {
    switch (_tabIndex) {
      case 0:
        return DocumentsTab(applicant: applicant, onPreview: _showFullImage);
      case 1:
        return PersonalInfoTab(viewModel: _viewModel);
      case 2:
        return const PaymentInfoTab();
      case 3:
        return const ActivityLogTab();
      default:
        return const SizedBox.shrink();
    }
  }
}