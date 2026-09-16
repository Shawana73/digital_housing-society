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
  State<PaymentVerificationScreen> createState() =>
      _PaymentVerificationScreenState();
}

class _PaymentVerificationScreenState
    extends State<PaymentVerificationScreen> {
  final PaymentVerificationViewModel _viewModel =
  PaymentVerificationViewModel();

  final TextEditingController _searchController = TextEditingController();

  /// Stores only the verified payments that the admin has opened for review.
  final Set<String> _reviewingPayments = {};

  @override
  void initState() {
    super.initState();

    _viewModel.addListener(_refresh);
    _viewModel.load();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_refresh);
    _viewModel.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirm(PaymentRecord payment, bool approve) async {
    final action = approve ? 'Approve' : 'Reject';

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AdminColors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (approve
                      ? AdminColors.success
                      : AdminColors.rejected)
                      .withOpacity(0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  approve
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: approve
                      ? AdminColors.success
                      : AdminColors.rejected,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$action payment?',
                  style: const TextStyle(
                    color: AdminColors.darkText,
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            approve
                ? 'Are you sure you want to verify transaction ${payment.transactionId}?'
                : 'Are you sure you want to reject transaction ${payment.transactionId}?',
            style: const TextStyle(
              color: AdminColors.greyText,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: Icon(
                approve
                    ? Icons.check_rounded
                    : Icons.close_rounded,
                size: 18,
              ),
              label: Text(action),
              style: FilledButton.styleFrom(
                backgroundColor: approve
                    ? AdminColors.success
                    : AdminColors.rejected,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    try {
      if (approve) {
        await _viewModel.approve(payment);
      } else {
        await _viewModel.reject(payment);
      }

      if (!mounted) return;

      setState(() {
        _reviewingPayments.remove(payment.id);
      });

      showAdminSnack(
        context,
        approve
            ? 'Payment verified successfully'
            : 'Payment rejected successfully',
      );
    } catch (e) {
      if (!mounted) return;

      showAdminSnack(
        context,
        'Unable to update payment. Please try again.',
      );
    }
  }

  void _openReview(PaymentRecord payment) {
    setState(() {
      _reviewingPayments.add(payment.id);
    });
  }

  void _previewReceipt(PaymentRecord payment) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: PremiumCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AdminColors.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: AdminColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Payment Receipt',
                        style: TextStyle(
                          color: AdminColors.darkText,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close_rounded),
                      color: AdminColors.greyText,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  height: 400,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AdminColors.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AdminColors.border,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: payment.receiptUrl.isNotEmpty
                      ? Image.network(
                    payment.receiptUrl,
                    fit: BoxFit.contain,
                    loadingBuilder:
                        (context, child, progress) {
                      if (progress == null) return child;

                      return const Center(
                        child: CircularProgressIndicator(
                          color: AdminColors.primary,
                        ),
                      );
                    },
                    errorBuilder:
                        (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.broken_image_rounded,
                              size: 64,
                              color: AdminColors.greyText,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Unable to load receipt',
                              style: TextStyle(
                                color: AdminColors.greyText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                      : const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 64,
                          color: AdminColors.greyText,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'No receipt image available',
                          style: TextStyle(
                            color: AdminColors.greyText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    payment.receiptNo,
                    style: const TextStyle(
                      color: AdminColors.darkText,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    payment.transactionId,
                    style: const TextStyle(
                      color: AdminColors.greyText,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Close Receipt'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
      isLoading: _viewModel.isLoading,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        children: [
          PaymentStatsBanner(payments: _viewModel.payments),
          FilterTabs(
            filters: _viewModel.filters,
            selected: _viewModel.selectedFilter,
            onSelected: _viewModel.setFilter,
          ),
          const SizedBox(height: 14),
          if (_viewModel.filteredPayments.isEmpty)
            EmptyState(
              icon: Icons.payments_rounded,
              title: 'No payments found',
              subtitle:
              'No payment receipt matches the current search or filter.',
              buttonText: 'Reset',
              onPressed: () {
                _searchController.clear();
                _viewModel.clearSearch();
                _viewModel.setFilter('All');
              },
            )
          else
            ..._viewModel.filteredPayments.map((payment) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: PaymentCard(
                payment: payment,
                isReviewing: _reviewingPayments.contains(payment.id),
                onApprove: () => _confirm(payment, true),
                onReject: () => _confirm(payment, false),
                onOpenReview: () => _openReview(payment),
                onPreview: () => _previewReceipt(payment),
              ),
            )),
        ],
      ),
    );
  }
}