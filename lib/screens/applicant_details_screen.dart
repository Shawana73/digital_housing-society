import 'package:flutter/material.dart';
import '../viewmodels/admin_view_models.dart';
import '../models/admin_models.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_shell.dart';
import '../widgets/app_snack.dart';
import '../widgets/premium_widgets.dart';

class ApplicantDetailsScreen extends StatefulWidget {
  final Applicant applicant;

  const ApplicantDetailsScreen({super.key, required this.applicant});

  @override
  State<ApplicantDetailsScreen> createState() =>
      _ApplicantDetailsScreenState();
}

class _ApplicantDetailsScreenState extends State<ApplicantDetailsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final ApplicantDetailsViewModel _viewModel =
  ApplicantDetailsViewModel();

  int _tabIndex = 0;

  final List<String> _tabs = const [
    'Documents',
    'Personal Info',
    'Payment Info',
    'References',
    'Activity Log',
  ];

  @override
  @override
  void initState() {
    super.initState();

    _viewModel.addListener(_refresh);

    _viewModel.loadApplicantDetails(widget.applicant);
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
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
                decoration: BoxDecoration(
                  gradient: AdminColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, size: 82, color: AdminColors.white),
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: const TextStyle(
                      color: AdminColors.darkText,
                      fontWeight: FontWeight.w900,
                      fontSize: 18)),
              const SizedBox(height: 8),
              const Text('Dummy preview image for local UI testing.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AdminColors.greyText, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close Preview')),
            ],
          ),
        ),
      ),
    );
  }

  void _setStatus(VerificationStatus status) {
    setState(() => widget.applicant.status = status);
    showAdminSnack(context, '${widget.applicant.name} marked ${status.label}');
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
        body: const Center(
          child: Text('Unable to load applicant details'),
        ),
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
          // ── Profile summary card ───────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AdminColors.white,
              borderRadius: BorderRadius.circular(AdminColors.radius),
              boxShadow: [
                BoxShadow(
                    color: AdminColors.primary.withOpacity(0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 12)),
              ],
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
                              style: const TextStyle(
                                  color: AdminColors.primary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20)),
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
                              border:
                              Border.all(color: AdminColors.white, width: 2),
                            ),
                            child: const Icon(Icons.check_rounded,
                                color: Colors.white, size: 12),
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: AdminColors.darkText,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      letterSpacing: -.4)),
                            ),
                            StatusPill(
                                label: applicant.status.label,
                                color: applicant.status.color),
                          ]),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: AdminColors.primary.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(applicant.id,
                                style: const TextStyle(
                                    color: AdminColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11)),
                          ),
                          const SizedBox(height: 10),
                          _MiniLine(icon: Icons.email_rounded, text: applicant.email),
                          const SizedBox(height: 6),
                          _MiniLine(icon: Icons.phone_rounded, text: applicant.phone),
                          const SizedBox(height: 6),
                          _MiniLine(
                              icon: Icons.location_on_rounded,
                              text: applicant.address,
                              maxLines: 2),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _Divider(),
                const SizedBox(height: 14),
                // Applied on / last updated mini grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      const Row(children: [
                        Expanded(
                            child: _MetaTile(
                                label: 'Applied On', value: '28 Jun 2026')),
                        SizedBox(width: 12),
                        Expanded(
                            child: _MetaTile(
                                label: 'Last Updated', value: '28 Jun 2026')),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        const Expanded(
                            child: _MetaTile(
                                label: 'Application Type',
                                value: 'Residential')),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _MetaTile(
                                label: 'Occupation',
                                value: applicant.occupation)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ── Tabs ─────────────────────────────────────────────────────
          _TabStrip(
            tabs: _tabs,
            selected: _tabIndex,
            onSelected: (i) => setState(() => _tabIndex = i),
          ),

          const SizedBox(height: 16),

          // ── Tab content ──────────────────────────────────────────────
          _buildTabContent(applicant),

          const SizedBox(height: 18),

          // ── Verification notes ──────────────────────────────────────
          PremiumCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Verification Notes',
                    style: TextStyle(
                        color: AdminColors.darkText,
                        fontWeight: FontWeight.w900,
                        fontSize: 15)),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: AdminColors.primary,
                      child: Text('AK',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11)),
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
                                  style: TextStyle(
                                      color: AdminColors.darkText,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AdminColors.primary.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Note',
                                    style: TextStyle(
                                        color: AdminColors.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 9)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          const Text('28 Jun 2026, 11:30 AM',
                              style: TextStyle(
                                  color: AdminColors.greyText,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10)),
                          const SizedBox(height: 6),
                          const Text(
                              'All documents look good. Need to verify income proof.',
                              style: TextStyle(
                                  color: AdminColors.darkText,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  height: 1.4)),
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
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _saveNote,
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 16)),
                    child: const Text('Save Note'),
                  ),
                ]),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ── Reject / Verify ─────────────────────────────────────────
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
                style: FilledButton.styleFrom(
                  backgroundColor: AdminColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
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
        return _DocumentsTab(applicant: applicant, onPreview: _showFullImage);
      case 1:
        return _PersonalInfoTab(applicant: applicant);
      case 2:
        return _PaymentInfoTab();
      case 3:
        return _ReferencesTab();
      case 4:
        return _ActivityLogTab();
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tabs strip
// ─────────────────────────────────────────────────────────────────────────────

class _TabStrip extends StatelessWidget {
  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onSelected;
  const _TabStrip(
      {required this.tabs, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 22),
        itemBuilder: (context, i) {
          final active = i == selected;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tabs[i],
                    style: TextStyle(
                        color: active
                            ? AdminColors.primary
                            : AdminColors.greyText,
                        fontWeight:
                        active ? FontWeight.w900 : FontWeight.w700,
                        fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  height: 3,
                  width: 28,
                  decoration: BoxDecoration(
                    color: active ? AdminColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Documents tab — 2-column grid matching the reference
// ─────────────────────────────────────────────────────────────────────────────

class _DocumentsTab extends StatelessWidget {
  final Applicant applicant;
  final void Function(String title, IconData icon) onPreview;
  const _DocumentsTab({required this.applicant, required this.onPreview});

  @override
  Widget build(BuildContext context) {
    final docs = applicant.documents;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Uploaded Documents',
            style: TextStyle(
                color: AdminColors.darkText,
                fontWeight: FontWeight.w900,
                fontSize: 15)),
        const SizedBox(height: 12),
        // Build rows of 2 so cards never overflow on small screens
        for (int i = 0; i < docs.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _DocTile(
                      doc: docs[i],
                      onTap: () => onPreview(docs[i].title, docs[i].icon),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: i + 1 < docs.length
                        ? _DocTile(
                      doc: docs[i + 1],
                      onTap: () =>
                          onPreview(docs[i + 1].title, docs[i + 1].icon),
                    )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
              child: OutlinedButton.icon(
                onPressed: () => showAdminSnack(context, 'Download clicked'),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Download'),
              )),
          const SizedBox(width: 10),
          Expanded(
              child: FilledButton.icon(
                onPressed: () => onPreview('All Documents', Icons.folder_copy_rounded),
                icon: const Icon(Icons.fullscreen_rounded, size: 18),
                label: const Text('View Full'),
              )),
        ]),
      ],
    );
  }
}

class _DocTile extends StatelessWidget {
  final ApplicantDocument doc;
  final VoidCallback onTap;
  const _DocTile({required this.doc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = doc.verified ? AdminColors.success : AdminColors.warning;
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: AdminColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(doc.icon, color: AdminColors.primary, size: 19),
            ),
            const Spacer(),
            _RoundGhostIcon(icon: Icons.visibility_outlined, onTap: onTap),
          ]),
          const SizedBox(height: 10),
          Text(doc.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AdminColors.darkText,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5)),
          const SizedBox(height: 4),
          const Text('Uploaded on 28 Jun 2026',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: AdminColors.greyText,
                  fontWeight: FontWeight.w600,
                  fontSize: 10.5)),
          const SizedBox(height: 8),
          StatusPill(label: doc.verified ? 'Verified' : 'Pending', color: color),
        ],
      ),
    );
  }
}

class _RoundGhostIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundGhostIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: AdminColors.background,
    borderRadius: BorderRadius.circular(9),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 28,
        width: 28,
        alignment: Alignment.center,
        child: Icon(icon, size: 14, color: AdminColors.darkText),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Personal Info tab
// ─────────────────────────────────────────────────────────────────────────────

class _PersonalInfoTab extends StatelessWidget {
  final ApplicantDetailsViewModel viewModel;

  const _PersonalInfoTab({
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(
            icon: Icons.badge_rounded,
            label: 'Applicant ID',
            value: viewModel.applicant?.id ?? 'Not available',
          ),

          InfoRow(
            icon: Icons.credit_card_rounded,
            label: 'CNIC',
            value: viewModel.cnic,
          ),

          InfoRow(
            icon: Icons.phone_rounded,
            label: 'Phone',
            value: viewModel.phone,
          ),

          InfoRow(
            icon: Icons.email_rounded,
            label: 'Email',
            value: viewModel.email,
          ),

          InfoRow(
            icon: Icons.location_on_rounded,
            label: 'Address',
            value: viewModel.address,
          ),

          InfoRow(
            icon: Icons.location_city_rounded,
            label: 'City',
            value: viewModel.city,
          ),

          InfoRow(
            icon: Icons.cake_rounded,
            label: 'Date of Birth',
            value: viewModel.dateOfBirth,
          ),

          InfoRow(
            icon: Icons.category_rounded,
            label: 'Application Type',
            value: viewModel.applicationType,
          ),

          InfoRow(
            icon: Icons.confirmation_number_rounded,
            label: 'Serial Number',
            value: viewModel.serialNumber,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment Info tab (dummy placeholder content, styled consistently)
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentInfoTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const PremiumCard(
      padding: EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(icon: Icons.receipt_long_rounded, label: 'Transaction ID', value: 'DH-882913'),
          InfoRow(icon: Icons.payments_rounded, label: 'Amount Paid', value: 'PKR 450,000'),
          InfoRow(icon: Icons.account_balance_rounded, label: 'Payment Method', value: 'Bank Transfer'),
          InfoRow(icon: Icons.event_rounded, label: 'Payment Date', value: '28 Jun 2026'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// References tab (dummy placeholder content)
// ─────────────────────────────────────────────────────────────────────────────

class _ReferencesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const PremiumCard(
      padding: EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(icon: Icons.person_rounded, label: 'Reference Name', value: 'Tariq Mehmood'),
          InfoRow(icon: Icons.phone_rounded, label: 'Reference Phone', value: '+92 301 9988776'),
          InfoRow(icon: Icons.badge_rounded, label: 'Relationship', value: 'Colleague'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity Log tab (dummy placeholder content)
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityLogTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final entries = [
      ('Application submitted', '28 Jun 2026, 9:02 AM'),
      ('CNIC documents uploaded', '28 Jun 2026, 9:14 AM'),
      ('Admin reviewed profile', '28 Jun 2026, 11:30 AM'),
    ];
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < entries.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == entries.length - 1 ? 0 : 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    height: 8,
                    width: 8,
                    decoration: const BoxDecoration(
                        color: AdminColors.primary, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entries[i].$1,
                            style: const TextStyle(
                                color: AdminColors.darkText,
                                fontWeight: FontWeight.w800,
                                fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(entries[i].$2,
                            style: const TextStyle(
                                color: AdminColors.greyText,
                                fontWeight: FontWeight.w600,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _MiniLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final int maxLines;
  const _MiniLine({required this.icon, required this.text, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AdminColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AdminColors.greyText,
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                  height: 1.3)),
        ),
      ],
    );
  }
}

class _MetaTile extends StatelessWidget {
  final String label;
  final String value;
  const _MetaTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AdminColors.greyText,
                fontWeight: FontWeight.w600,
                fontSize: 11)),
        const SizedBox(height: 3),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: AdminColors.darkText,
                fontWeight: FontWeight.w800,
                fontSize: 12.5)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    color: AdminColors.primary.withOpacity(0.07),
  );
}
