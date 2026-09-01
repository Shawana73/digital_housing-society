import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/premium_widgets.dart';

class DealerCard extends StatelessWidget {
  final Dealer dealer;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onView;
  const DealerCard({super.key, required this.dealer, required this.onApprove, required this.onReject, required this.onView});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onView,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          GradientIconBox(icon: Icons.real_estate_agent_rounded, color: dealer.status.color),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(dealer.name, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 4),
            Text(dealer.agency, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w700, fontSize: 12)),
          ])),
          StatusPill(label: dealer.status.label, color: dealer.status.color),
        ]),
        const SizedBox(height: 12),
        InfoRow(icon: Icons.credit_card_rounded, label: 'CNIC', value: dealer.cnic),
        InfoRow(icon: Icons.phone_rounded, label: 'Phone', value: dealer.phone),
        InfoRow(icon: Icons.location_city_rounded, label: 'City', value: dealer.city),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: onReject, icon: const Icon(Icons.close_rounded), label: const Text('Reject'))),
          const SizedBox(width: 10),
          Expanded(child: FilledButton.icon(onPressed: onApprove, icon: const Icon(Icons.check_rounded), label: const Text('Approve'))),
        ]),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: TextButton.icon(onPressed: onView, icon: const Icon(Icons.visibility_rounded), label: const Text('View Profile'))),
      ]),
    );
  }
}