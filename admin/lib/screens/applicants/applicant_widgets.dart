import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/premium_widgets.dart';

class ApplicantStatsBanner extends StatelessWidget {
  final List<Applicant> applicants;
  const ApplicantStatsBanner({super.key, required this.applicants});

  @override
  Widget build(BuildContext context) {
    final total = applicants.length;
    final pending = applicants.where((a) => a.status == VerificationStatus.pending).length;
    final verified = applicants.where((a) => a.status == VerificationStatus.verified).length;
    final rejected = applicants.where((a) => a.status == VerificationStatus.rejected).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 230 + 74,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
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
                      BoxShadow(color: AdminColors.primary.withOpacity(0.28), blurRadius: 30, offset: const Offset(0, 14)),
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
                    const Positioned(right: -34, top: -34, child: ApplicantGlow(110, opacity: 0.08)),
                    const Positioned(left: -46, bottom: -46, child: ApplicantGlow(120, opacity: 0.05)),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 22, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Applicant Verification',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -.5)),
                          SizedBox(height: 4),
                          Text('Review and verify applicant documents',
                              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 230 - 74,
                child: Container(
                  height: 148,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AdminColors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 24, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Row(children: [
                    Expanded(child: ApplicantStatTile(icon: Icons.groups_rounded, iconColor: AdminColors.primary, label: 'Total', value: '$total', trend: '+12.8%')),
                    ApplicantVDivider(),
                    Expanded(child: ApplicantStatTile(icon: Icons.hourglass_top_rounded, iconColor: AdminColors.warning, label: 'Pending', value: '$pending', trend: '+8.4%')),
                    ApplicantVDivider(),
                    Expanded(child: ApplicantStatTile(icon: Icons.verified_rounded, iconColor: AdminColors.success, label: 'Verified', value: '$verified', trend: '+16.2%')),
                    ApplicantVDivider(),
                    Expanded(child: ApplicantStatTile(icon: Icons.cancel_rounded, iconColor: AdminColors.rejected, label: 'Rejected', value: '$rejected', trend: '-2.1%', trendDown: true)),
                  ]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class ApplicantVDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 54,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    color: AdminColors.border,
  );
}

class ApplicantStatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String trend;
  final bool trendDown;
  const ApplicantStatTile({
    super.key,
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
          decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w700, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: -.4)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: (trendDown ? AdminColors.rejected : AdminColors.success).withOpacity(0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(trend,
              style: TextStyle(color: trendDown ? AdminColors.rejected : AdminColors.success, fontWeight: FontWeight.w800, fontSize: 9)),
        ),
      ],
    );
  }
}

class ApplicantRow extends StatelessWidget {
  final Applicant applicant;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onTap;
  const ApplicantRow({
    super.key,
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
          Hero(
            tag: 'applicant-${applicant.id}',
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AdminColors.primary.withOpacity(0.12),
              child: Text(applicant.avatarLetters,
                  style: const TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w900, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(applicant.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 14)),
                const SizedBox(height: 3),
                Text(applicant.email,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 11)),
                const SizedBox(height: 5),
                Row(children: [
                  Text(applicant.id, style: const TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w800, fontSize: 10)),
                  const SizedBox(width: 8),
                  Container(width: 3, height: 3, decoration: const BoxDecoration(color: AdminColors.greyText, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  const Text('28 Jun 2026', style: TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 10)),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusPill(label: applicant.status.label, color: applicant.status.color),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ApplicantRoundIconButton(icon: Icons.visibility_outlined, background: AdminColors.background, iconColor: AdminColors.darkText, onTap: onTap),
                  const SizedBox(width: 6),
                  ApplicantRoundIconButton(icon: Icons.check_rounded, background: AdminColors.success, iconColor: AdminColors.white, onTap: onApprove),
                  const SizedBox(width: 6),
                  ApplicantRoundIconButton(icon: Icons.close_rounded, background: AdminColors.rejected, iconColor: AdminColors.white, onTap: onReject),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ApplicantRoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color iconColor;
  final VoidCallback onTap;
  const ApplicantRoundIconButton({
    super.key,
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

class ApplicantGlow extends StatelessWidget {
  final double size;
  final double opacity;
  const ApplicantGlow(this.size, {super.key, this.opacity = 0.14});

  @override
  Widget build(BuildContext context) => Container(
    height: size,
    width: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(opacity)),
  );
}