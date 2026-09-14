import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/premium_widgets.dart';

class PaymentCard extends StatelessWidget {
  final PaymentRecord payment;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onPreview;

  const PaymentCard({super.key, required this.payment, required this.onApprove, required this.onReject, required this.onPreview});

  @override
  Widget build(BuildContext context) {
    final isLocked = payment.status != PaymentStatus.pending;

    return PremiumCard(
      onTap: onPreview,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            GradientIconBox(icon: Icons.payments_rounded, color: payment.status.color),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(payment.applicantName, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 4),
              Text(payment.transactionId, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w700, fontSize: 12)),
            ])),
            StatusPill(label: payment.status.label, color: payment.status.color),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: InfoRow(icon: Icons.account_balance_wallet_rounded, label: 'Amount', value: payment.amount)),
          ]),
          InfoRow(icon: Icons.calendar_month_rounded, label: 'Date', value: payment.date),
          InfoRow(icon: Icons.receipt_rounded, label: 'Receipt', value: payment.receiptNo),
          InfoRow(icon: Icons.credit_score_rounded, label: 'Method', value: payment.method),
          const SizedBox(height: 10),
          DocumentPreviewBox(
            title: 'Receipt Image',
            subtitle: payment.receiptNo,
            icon: Icons.image_rounded,
            verified: payment.status == PaymentStatus.verified,
            onTap: onPreview,
          ),
          const SizedBox(height: 14),
          if (isLocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: payment.status.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: payment.status.color.withOpacity(0.3)),
              ),
              child: Row(children: [
                Icon(
                  payment.status == PaymentStatus.verified ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: payment.status.color,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    payment.status == PaymentStatus.verified
                        ? 'This payment has been verified'
                        : 'This payment has been rejected',
                    style: TextStyle(color: payment.status.color, fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ]),
            )
          else
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: onReject, icon: const Icon(Icons.close_rounded), label: const Text('Reject'))),
              const SizedBox(width: 10),
              Expanded(child: FilledButton.icon(onPressed: onApprove, icon: const Icon(Icons.check_rounded), label: const Text('Approve'))),
            ]),
        ],
      ),
    );
  }
}