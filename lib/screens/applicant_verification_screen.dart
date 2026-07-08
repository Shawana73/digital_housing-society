import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../models/admin_models.dart';
import '../theme/admin_theme.dart';
import '../viewmodels/admin_view_models.dart';
import '../widgets/admin_shell.dart';
import '../widgets/app_snack.dart';
import '../widgets/premium_widgets.dart';

class ApplicantVerificationScreen extends StatefulWidget {
  const ApplicantVerificationScreen({super.key});

  @override
  State<ApplicantVerificationScreen> createState() =>
      _ApplicantVerificationScreenState();
}

class _ApplicantVerificationScreenState
    extends State<ApplicantVerificationScreen> {
  final ApplicantVerificationViewModel _viewModel =
  ApplicantVerificationViewModel();
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AdminColors.radius)),
        title: Text(approve ? 'Approve Applicant?' : 'Reject Applicant?',
            style: const TextStyle(
                color: AdminColors.darkText, fontWeight: FontWeight.w900)),
        content: Text(
          '${applicant.name} will be marked as '
              '${approve ? 'verified' : 'rejected'}.',
          style: const TextStyle(color: AdminColors.greyText),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(approve ? 'Approve' : 'Reject')),
        ],
      ),
    );
    if (result == true) {
      approve ? _viewModel.approve(applicant) : _viewModel.reject(applicant);
      if (mounted) {
        showAdminSnack(
            context, '${applicant.name} ${approve ? 'approved' : 'rejected'}');
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
      onFabTap: () => showAdminSnack(context, 'Add applicant clicked'),
      fabLabel: 'Applicant',
      fabIcon: Icons.person_add_alt_1_rounded,
      isLoading: _viewModel.isLoading,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        children: [
          // ── Stat strip (image background like dashboard hero) ────────
          _StatsBanner(applicants: _viewModel.applicants),

          const SizedBox(height: 22),

          // ── "Applicants" header + sort ────────────────────────────────
          Row(children: [
            const Expanded(
              child: Text('Applicants',
                  style: TextStyle(
                      color: AdminColors.darkText,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: -.4)),
            ),
            GestureDetector(
              onTap: () => showAdminSnack(context, 'Sort clicked'),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Sort',
                    style: TextStyle(
                        color: AdminColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
                SizedBox(width: 4),
                Icon(Icons.swap_vert_rounded,
                    color: AdminColors.primary, size: 18),
              ]),
            ),
          ]),

          const SizedBox(height: 12),

          // ── Filter chips ──────────────────────────────────────────────
          FilterTabs(
            filters: _viewModel.filters,
            selected: _viewModel.selectedFilter,
            onSelected: _viewModel.setFilter,
          ),

          const SizedBox(height: 14),

          // ── Applicant rows ───────────────────────────────────────────
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
              child: _ApplicantRow(
                applicant: applicant,
                onApprove: () => _confirmStatus(applicant, true),
                onReject: () => _confirmStatus(applicant, false),
                onTap: () => Navigator.pushNamed(
                    context, AdminRoutes.applicantDetails,
                    arguments: applicant),
              ),
            )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats banner — purple hero card with background image + 4 stat tiles
// ─────────────────────────────────────────────────────────────────────────────

class _StatsBanner extends StatelessWidget {
  final List<Applicant> applicants;
  const _StatsBanner({required this.applicants});

  @override
  Widget build(BuildContext context) {
    final total = applicants.length;
    final pending =
        applicants.where((a) => a.status == VerificationStatus.pending).length;
    final verified = applicants
        .where((a) => a.status == VerificationStatus.verified)
        .length;
    final rejected = applicants
        .where((a) => a.status == VerificationStatus.rejected)
        .length;

    // The purple/image banner and the white stat card are two separate
    // layers in a Stack, with the stat card pulled UP by exactly half its
    // own height — this guarantees a true 50% overlap (half sits on the
    // purple banner, half sits below it) regardless of content size.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 230 + 74, // banner height + half the overlapping stat card
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Purple banner (image + gradient + heading text) ─────────
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Container(
                  height: 230,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/modern_apartment.png'),
                      fit: BoxFit.cover,
                      alignment: Alignment.topRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: AdminColors.primary.withOpacity(0.28),
                          blurRadius: 30,
                          offset: const Offset(0, 14)),
                    ],
                  ),
                  child: Stack(children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              const Color(0xFF5A2FE0).withOpacity(0.97),
                              const Color(0xFF6A3CEF).withOpacity(0.85),
                              const Color(0xFF6A3CEF).withOpacity(0.52),
                            ],
                            stops: const [0.0, 0.55, 1.0],
                          ),
                        ),
                      ),
                    ),
                    const Positioned(right: -34, top: -34, child: _Glow(110, opacity: 0.08)),
                    const Positioned(left: -46, bottom: -46, child: _Glow(120, opacity: 0.05)),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 22, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Applicant Verification',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                  letterSpacing: -.5)),
                          SizedBox(height: 4),
                          Text('Review and verify applicant documents',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),

              // ── White stat card — pulled up by exactly half its height ──
              Positioned(
                left: 0,
                right: 0,
                top: 230 - 74, // banner height − half of stat card height (148/2)
                child: Container(
                  height: 148,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AdminColors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Row(children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.groups_rounded,
                        iconColor: AdminColors.primary,
                        label: 'Total',
                        value: '$total',
                        trend: '+12.8%',
                      ),
                    ),
                    _VDivider(),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.hourglass_top_rounded,
                        iconColor: AdminColors.warning,
                        label: 'Pending',
                        value: '$pending',
                        trend: '+8.4%',
                      ),
                    ),
                    _VDivider(),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.verified_rounded,
                        iconColor: AdminColors.success,
                        label: 'Verified',
                        value: '$verified',
                        trend: '+16.2%',
                      ),
                    ),
                    _VDivider(),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.cancel_rounded,
                        iconColor: AdminColors.rejected,
                        label: 'Rejected',
                        value: '$rejected',
                        trend: '-2.1%',
                        trendDown: true,
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
        // Small gap before the "Applicants" section header.
        const SizedBox(height: 20),
      ],
    );
  }
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 54,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    color: AdminColors.border,
  );
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String trend;
  final bool trendDown;
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.trend,
    this.trendDown = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 30,
          width: 30,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(
                color: AdminColors.greyText,
                fontWeight: FontWeight.w700,
                fontSize: 10)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: AdminColors.darkText,
                fontWeight: FontWeight.w900,
                fontSize: 17,
                letterSpacing: -.4)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: (trendDown ? AdminColors.rejected : AdminColors.success)
                .withOpacity(0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(trend,
              style: TextStyle(
                  color: trendDown
                      ? AdminColors.rejected
                      : AdminColors.success,
                  fontWeight: FontWeight.w800,
                  fontSize: 9)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Applicant row — compact list-style card matching the reference
// ─────────────────────────────────────────────────────────────────────────────

class _ApplicantRow extends StatelessWidget {
  final Applicant applicant;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onTap;
  const _ApplicantRow({
    required this.applicant,
    required this.onApprove,
    required this.onReject,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Purple logo avatar (instead of photo) per request
          Hero(
            tag: 'applicant-${applicant.id}',
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AdminColors.primary.withOpacity(0.12),
              child: Text(
                applicant.avatarLetters,
                style: const TextStyle(
                    color: AdminColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name + email + id/date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(applicant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AdminColors.darkText,
                        fontWeight: FontWeight.w900,
                        fontSize: 14)),
                const SizedBox(height: 3),
                Text(applicant.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AdminColors.greyText,
                        fontWeight: FontWeight.w600,
                        fontSize: 11)),
                const SizedBox(height: 5),
                Row(children: [
                  Text(applicant.id,
                      style: const TextStyle(
                          color: AdminColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 10)),
                  const SizedBox(width: 8),
                  Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                          color: AdminColors.greyText, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  const Text('28 Jun 2026',
                      style: TextStyle(
                          color: AdminColors.greyText,
                          fontWeight: FontWeight.w600,
                          fontSize: 10)),
                ]),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Status pill stacked above action icons
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusPill(
                  label: applicant.status.label,
                  color: applicant.status.color),
              const SizedBox(height: 8),
              Row(mainAxisSize: MainAxisSize.min, children: [
                _RoundIconButton(
                  icon: Icons.visibility_outlined,
                  background: AdminColors.background,
                  iconColor: AdminColors.darkText,
                  onTap: onTap,
                ),
                const SizedBox(width: 6),
                _RoundIconButton(
                  icon: Icons.edit_rounded,
                  background: AdminColors.primary,
                  iconColor: AdminColors.white,
                  onTap: onTap,
                ),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color iconColor;
  final VoidCallback onTap;
  const _RoundIconButton({
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          height: 32,
          width: 32,
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: iconColor),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Decorative glow
// ─────────────────────────────────────────────────────────────────────────────

class _Glow extends StatelessWidget {
  final double size;
  final double opacity;
  const _Glow(this.size, {this.opacity = 0.14});

  @override
  Widget build(BuildContext context) => Container(
    height: size,
    width: size,
    decoration: BoxDecoration(
        shape: BoxShape.circle, color: Colors.white.withOpacity(opacity)),
  );
}
