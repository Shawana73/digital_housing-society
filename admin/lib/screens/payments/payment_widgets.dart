import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/premium_widgets.dart';

class PaymentCard extends StatelessWidget {
  final PaymentRecord payment;
  final bool isReviewing;

  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onOpenReview;
  final VoidCallback onPreview;

  const PaymentCard({
    super.key,
    required this.payment,
    required this.isReviewing,
    required this.onApprove,
    required this.onReject,
    required this.onOpenReview,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = payment.status == PaymentStatus.pending;
    final isVerified = payment.status == PaymentStatus.verified;
    final isRejected = payment.status == PaymentStatus.rejected;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientIconBox(
                icon: Icons.payments_rounded,
                color: payment.status.color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.applicantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminColors.darkText,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      payment.transactionId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminColors.greyText,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              StatusPill(
                label: payment.status.label,
                color: payment.status.color,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // PAYMENT DETAILS
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AdminColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AdminColors.border,
              ),
            ),
            child: Column(
              children: [
                InfoRow(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Amount',
                  value: payment.amount,
                ),
                InfoRow(
                  icon: Icons.calendar_month_rounded,
                  label: 'Date',
                  value: payment.date,
                ),
                InfoRow(
                  icon: Icons.receipt_rounded,
                  label: 'Receipt',
                  value: payment.receiptNo,
                ),
                InfoRow(
                  icon: Icons.credit_score_rounded,
                  label: 'Method',
                  value: payment.method,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ONLY THIS PART IS CLICKABLE
          DocumentPreviewBox(
            title: 'Receipt Image',
            subtitle: payment.receiptNo,
            icon: Icons.image_rounded,
            verified: isVerified,
            onTap: onPreview,
          ),

          const SizedBox(height: 14),

          // PENDING
          if (isPending) _buildPendingActions(),

          // VERIFIED
          if (isVerified) _buildReviewedStatus(),

          // REJECTED
          if (isRejected) _buildRejectedStatus(),
        ],
      ),
    );
  }

  Widget _buildPendingActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onReject,
            icon: const Icon(
              Icons.close_rounded,
              size: 19,
            ),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AdminColors.rejected,
              side: BorderSide(
                color: AdminColors.rejected.withOpacity(0.45),
              ),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: onApprove,
            icon: const Icon(
              Icons.check_rounded,
              size: 19,
            ),
            label: const Text('Approve'),
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.success,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewedStatus() {
    if (isReviewing) {
      return _buildReviewActions(
        message:
        'Review mode is open. You can update this payment.',
      );
    }

    return Column(
      children: [
        _statusMessage(
          icon: Icons.check_circle_rounded,
          color: AdminColors.success,
          text: 'This payment has been verified',
        ),
        const SizedBox(height: 10),
        _openReviewButton(),
      ],
    );
  }

  Widget _buildRejectedStatus() {
    if (isReviewing) {
      return _buildReviewActions(
        message:
        'Review mode is open. You can update this payment.',
      );
    }

    return Column(
      children: [
        _statusMessage(
          icon: Icons.cancel_rounded,
          color: AdminColors.rejected,
          text: 'This payment has been rejected',
        ),
        const SizedBox(height: 10),
        _openReviewButton(),
      ],
    );
  }

  Widget _statusMessage({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _openReviewButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onOpenReview,
        icon: const Icon(
          Icons.rate_review_rounded,
          size: 19,
        ),
        label: const Text('Open for Review'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AdminColors.primary,
          side: BorderSide(
            color: AdminColors.primary.withOpacity(0.35),
          ),
          backgroundColor:
          AdminColors.primary.withOpacity(0.04),
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewActions({
    required String message,
  }) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: AdminColors.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.visibility_rounded,
                color: AdminColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AdminColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReject,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 19,
                ),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminColors.rejected,
                  side: BorderSide(
                    color: AdminColors.rejected.withOpacity(0.45),
                  ),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: onApprove,
                icon: const Icon(
                  Icons.verified_rounded,
                  size: 19,
                ),
                label: const Text('Approve'),
                style: FilledButton.styleFrom(
                  backgroundColor: AdminColors.success,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
class PaymentStatsBanner extends StatelessWidget {
  final List<PaymentRecord> payments;
  const PaymentStatsBanner({super.key, required this.payments});

  @override
  Widget build(BuildContext context) {
    final total = payments.length;
    final pending = payments.where((p) => p.status == PaymentStatus.pending).length;
    final verified = payments.where((p) => p.status == PaymentStatus.verified).length;
    final rejected = payments.where((p) => p.status == PaymentStatus.rejected).length;

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
                      image: AssetImage('assets/images/Green_Valley_Villa.png'),
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
                              const Color(0xFF5A2FE0).withOpacity(0.55),
                              const Color(0xFF6A3CEF).withOpacity(0.30),
                              const Color(0xFF6A3CEF).withOpacity(0.10),
                            ],
                            stops: const [0.0, 0.55, 1.0],
                          ),
                        ),
                      ),
                    ),
                    const Positioned(right: -34, top: -34, child: PaymentGlow(110, opacity: 0.08)),
                    const Positioned(left: -46, bottom: -46, child: PaymentGlow(120, opacity: 0.05)),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 22, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Payment Verification',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -.5)),
                          SizedBox(height: 4),
                          Text('Review and verify payment receipts',
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
                    Expanded(child: PaymentStatTile(icon: Icons.payments_rounded, iconColor: AdminColors.primary, label: 'Total', value: '$total')),
                    PaymentVDivider(),
                    Expanded(child: PaymentStatTile(icon: Icons.hourglass_top_rounded, iconColor: AdminColors.warning, label: 'Pending', value: '$pending')),
                    PaymentVDivider(),
                    Expanded(child: PaymentStatTile(icon: Icons.verified_rounded, iconColor: AdminColors.success, label: 'Verified', value: '$verified')),
                    PaymentVDivider(),
                    Expanded(child: PaymentStatTile(icon: Icons.cancel_rounded, iconColor: AdminColors.rejected, label: 'Rejected', value: '$rejected')),
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

class PaymentVDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 54,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    color: AdminColors.border,
  );
}

class PaymentStatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const PaymentStatTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
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
      ],
    );
  }
}

class PaymentGlow extends StatelessWidget {
  final double size;
  final double opacity;
  const PaymentGlow(this.size, {super.key, this.opacity = 0.14});

  @override
  Widget build(BuildContext context) => Container(
    height: size,
    width: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(opacity)),
  );
}