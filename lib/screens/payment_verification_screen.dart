import 'package:flutter/material.dart';

import '../models/admin_models.dart';
import '../theme/admin_theme.dart';
import '../viewmodels/admin_view_models.dart';
import '../widgets/admin_shell.dart';
import '../widgets/app_snack.dart';
import '../widgets/premium_widgets.dart';

class PaymentVerificationScreen extends StatefulWidget {
  const PaymentVerificationScreen({super.key});

  @override
  State<PaymentVerificationScreen> createState() => _PaymentVerificationScreenState();
}

class _PaymentVerificationScreenState extends State<PaymentVerificationScreen> {
  final PaymentVerificationViewModel _viewModel = PaymentVerificationViewModel();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_refresh);
    _viewModel.load();
  }

  void _refresh() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    _viewModel.removeListener(_refresh);
    _viewModel.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirm(PaymentRecord payment, bool approve) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminColors.radius)),
        title: Text(approve ? 'Approve payment?' : 'Reject payment?'),
        content: Text('${payment.transactionId} will be marked as ${approve ? 'verified' : 'rejected'}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(approve ? 'Approve' : 'Reject')),
        ],
      ),
    );
    if (ok == true) {
      approve ? _viewModel.approve(payment) : _viewModel.reject(payment);
      if (mounted) showAdminSnack(context, 'Payment ${approve ? 'approved' : 'rejected'}');
    }
  }

  void _previewReceipt(PaymentRecord payment) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: PremiumCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 220,
                decoration: BoxDecoration(gradient: AdminColors.primaryGradient, borderRadius: BorderRadius.circular(24)),
                child: const Center(child: Icon(Icons.receipt_long_rounded, color: AdminColors.white, size: 90)),
              ),
              const SizedBox(height: 16),
              Text(payment.receiptNo, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 6),
              Text(payment.transactionId, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Close Receipt')),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Payments',
      selectedIndex: 0,
      searchController: _searchController,
      searchHint: 'Search payment, transaction ID...',
      onSearchChanged: _viewModel.search,
      onSearchClear: () { _searchController.clear(); _viewModel.clearSearch(); },
      onFabTap: () => showAdminSnack(context, 'Manual payment entry clicked'),
      fabLabel: 'Payment',
      fabIcon: Icons.add_card_rounded,
      isLoading: _viewModel.isLoading,
      body: Column(
        children: [
          FilterTabs(filters: _viewModel.filters, selected: _viewModel.selectedFilter, onSelected: _viewModel.setFilter),
          const SizedBox(height: 12),
          Expanded(
            child: _viewModel.filteredPayments.isEmpty
                ? EmptyState(icon: Icons.payments_rounded, title: 'No payments found', subtitle: 'No payment receipt matches current filter.', buttonText: 'Reset', onPressed: () { _searchController.clear(); _viewModel.clearSearch(); _viewModel.setFilter('All'); })
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    itemCount: _viewModel.filteredPayments.length,
                    itemBuilder: (context, index) {
                      final payment = _viewModel.filteredPayments[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _PaymentCard(
                          payment: payment,
                          onApprove: () => _confirm(payment, true),
                          onReject: () => _confirm(payment, false),
                          onPreview: () => _previewReceipt(payment),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentRecord payment;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onPreview;

  const _PaymentCard({required this.payment, required this.onApprove, required this.onReject, required this.onPreview});

  @override
  Widget build(BuildContext context) {
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
            PopupMenuButton<String>(
              color: AdminColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              onSelected: (value) {
                if (value == 'receipt') onPreview();
                if (value == 'approve') onApprove();
                if (value == 'reject') onReject();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'receipt', child: PopupMenuRow(icon: Icons.receipt_long_rounded, text: 'View Receipt')),
                PopupMenuItem(value: 'approve', child: PopupMenuRow(icon: Icons.check_circle_rounded, text: 'Approve')),
                PopupMenuItem(value: 'reject', child: PopupMenuRow(icon: Icons.cancel_rounded, text: 'Reject')),
              ],
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: InfoRow(icon: Icons.account_balance_wallet_rounded, label: 'Amount', value: payment.amount)),
          ]),
          InfoRow(icon: Icons.calendar_month_rounded, label: 'Date', value: payment.date),
          InfoRow(icon: Icons.receipt_rounded, label: 'Receipt', value: payment.receiptNo),
          InfoRow(icon: Icons.credit_score_rounded, label: 'Method', value: payment.method),
          const SizedBox(height: 10),
          DocumentPreviewBox(title: 'Receipt Image', subtitle: payment.receiptNo, icon: Icons.image_rounded, verified: payment.status != PaymentStatus.rejected, onTap: onPreview),
          const SizedBox(height: 14),
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
