import 'package:flutter/material.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/premium_widgets.dart';

class BallotingOverviewTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const BallotingOverviewTile({super.key, required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 19),
      ),
      const SizedBox(height: 8),
      Text(label, textAlign: TextAlign.center,
          style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w700, fontSize: 9.5, height: 1.2)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -.4)),
    ]);
  }
}

class BallotingVDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 60, margin: const EdgeInsets.symmetric(horizontal: 6), color: AdminColors.border);
}

class BallotingSchemeCard extends StatelessWidget {
  final String name;
  final String size;
  final int eligibleApplicants;
  final int availablePlots;
  final String date;
  final String status;
  final Color statusColor;
  final String imagePath;
  final String eligibleLabel;
  final String plotsLabel;
  final VoidCallback onStart;

  const BallotingSchemeCard({
    super.key,
    required this.name,
    required this.size,
    required this.eligibleApplicants,
    required this.availablePlots,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.imagePath,
    required this.onStart,
    this.eligibleLabel = 'Eligible Applicants',
    this.plotsLabel = 'Available Plots',
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              imagePath,
              height: 72,
              width: 82,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 72,
                width: 82,
                decoration: BoxDecoration(color: AdminColors.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.villa_rounded, color: AdminColors.primary, size: 32),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Text(name,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 14, height: 1.2)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 10)),
                ),
              ]),
              const SizedBox(height: 5),
              Text(size, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 12)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: BallotingMiniStat(icon: Icons.groups_rounded, label: eligibleLabel, value: '$eligibleApplicants')),
          Container(width: 1, height: 36, color: AdminColors.border),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: BallotingMiniStat(icon: Icons.home_work_rounded, label: plotsLabel, value: '$availablePlots'),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        const Row(children: [
          Icon(Icons.calendar_today_rounded, color: AdminColors.primary, size: 13),
          SizedBox(width: 6),
          Text('Balloting Date', style: TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 11)),
        ]),
        const SizedBox(height: 3),
        Text(date, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w800, fontSize: 12)),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_circle_rounded, size: 18),
            label: const Text('Start Balloting', style: TextStyle(fontWeight: FontWeight.w900)),
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ]),
    );
  }
}

class BallotingMiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const BallotingMiniStat({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: AdminColors.primary, size: 13),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 10)),
      ]),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 15)),
    ]);
  }
}

class BallotingHistoryCard extends StatelessWidget {
  final String name;
  final String size;
  final String date;
  final VoidCallback onTap;
  const BallotingHistoryCard({super.key, required this.name, required this.size, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/images/Royal Enclave.png',
            height: 56,
            width: 64,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 56,
              width: 64,
              decoration: BoxDecoration(color: AdminColors.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.domain_rounded, color: AdminColors.primary, size: 26),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(name,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 14))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: AdminColors.success.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
              child: const Text('Completed', style: TextStyle(color: AdminColors.success, fontWeight: FontWeight.w800, fontSize: 10)),
            ),
          ]),
          const SizedBox(height: 3),
          Text(size, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.calendar_today_rounded, color: AdminColors.primary, size: 12),
            const SizedBox(width: 5),
            Text(date, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 11)),
          ]),
        ])),
        const Icon(Icons.chevron_right_rounded, color: AdminColors.greyText, size: 20),
      ]),
    );
  }
}

class BallotingSectionLabel extends StatelessWidget {
  final String text;
  const BallotingSectionLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: -.3));
}