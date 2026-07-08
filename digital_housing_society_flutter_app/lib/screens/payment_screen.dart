import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/payment_service.dart';
import '../services/result_service.dart';
import '../widgets/app_text_field.dart';
import '../widgets/luxury_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/responsive_screen.dart';
import 'balloting_status_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});
  static const routeName = '/payment';

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController(text: '25000');
  final _reference = TextEditingController();
  String _purpose = 'Application Fee';
  bool _loading = false;
  bool _argsRead = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsRead) return;
    _argsRead = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['purpose'] == 'Plot Installment') {
      _purpose = 'Plot Installment';
      _amount.text = '50000';
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_purpose == 'Plot Installment') {
      final result = await ResultService.currentUserResult();
      if (!ResultService.isSelected(result)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Installment payment opens after selected ballot result / plot assignment.')));
        return;
      }
    }

    setState(() => _loading = true);
    try {
      final reference = await PaymentService.submitPayment(
        amount: double.parse(_amount.text),
        purpose: _purpose,
        referenceNo: _reference.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment submitted. Reference: $reference')));
      Navigator.pushReplacementNamed(context, BallotingStatusScreen.routeName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScreen(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
            const SizedBox(height: 10),
            const Text('PAYMENT\nPROCESSING', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.primaryText, height: 1.1)),
            const SizedBox(height: 8),
            const Text('Stripe Test Mode payment will stay pending until admin verifies it.', style: TextStyle(color: AppColors.secondaryText, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            LuxuryCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(22)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_purpose.toUpperCase(), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        const SizedBox(height: 8),
                        Text(_purpose == 'Application Fee' ? 'PKR 25,000' : 'PKR 50,000', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28)),
                        const SizedBox(height: 4),
                        Text(
                          _purpose == 'Application Fee' ? 'Required before admin can approve balloting eligibility' : 'Available after selected result and plot assignment',
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 8),
                    child: Text('PAYMENT PURPOSE', style: TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _purpose,
                    items: const ['Application Fee', 'Plot Installment'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() {
                      _purpose = v!;
                      _amount.text = _purpose == 'Application Fee' ? '25000' : '50000';
                    }),
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.receipt_long_rounded, color: AppColors.primaryPurple)),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Amount',
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final value = double.tryParse(v ?? '');
                      if (value == null || value <= 0) return 'Enter valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 8),
                    child: Text('PAYMENT METHOD', style: TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: 'Stripe Test Mode',
                    items: const ['Stripe Test Mode'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (_) {},
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.credit_card_rounded, color: AppColors.primaryPurple)),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Stripe Test Reference',
                    controller: _reference,
                    hintText: 'Leave empty to auto-generate test reference',
                    prefixIcon: Icons.confirmation_number_rounded,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.warningOrange.withOpacity(0.10), borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.warningOrange.withOpacity(0.25))),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_rounded, color: AppColors.warningOrange),
                        SizedBox(width: 10),
                        Expanded(child: Text('Strict flow: applicant submits Stripe test payment → status becomes Pending Verification → admin verifies payment → status becomes Paid/Verified → balloting eligibility can be approved.', style: TextStyle(color: AppColors.secondaryText, fontWeight: FontWeight.w700, height: 1.35))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(text: 'SUBMIT PAYMENT', icon: Icons.lock_rounded, loading: _loading, onPressed: _submit),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
