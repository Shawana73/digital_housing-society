import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_shell.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/premium_widgets.dart';
import 'payment_viewmodel.dart';
import 'payment_widgets.dart';

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
      onSearchClear: () {
        _searchController.clear();
        _viewModel.clearSearch();
      },
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
                ? EmptyState(
                icon: Icons.payments_rounded,
                title: 'No payments found',
                subtitle: 'No payment receipt matches current filter.',
                buttonText: 'Reset',
                onPressed: () {
                  _searchController.clear();
                  _viewModel.clearSearch();
                  _viewModel.setFilter('All');
                })
                : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              itemCount: _viewModel.filteredPayments.length,
              itemBuilder: (context, index) {
                final payment = _viewModel.filteredPayments[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: PaymentCard(
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