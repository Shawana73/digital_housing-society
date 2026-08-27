import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/application_model.dart';
import '../models/payment_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_text_styles.dart';
import '../utils/formatters_validators.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/header_actions.dart';
import '../widgets/status_badge.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final _reference = TextEditingController();
  final _cardLast4 = TextEditingController(text: '4242');
  static const String _method = 'Stripe Test Mode';
  ApplicationModel? _application;
  PaymentModel? _payment;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reference.dispose();
    _cardLast4.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final applicationDoc = await _firestoreService.getApplication(uid);
      final paymentDoc = await _firestoreService.getPayment(uid);
      setState(() {
        _application = applicationDoc == null ? null : ApplicationModel.fromFirestore(applicationDoc);
        _payment = paymentDoc == null ? null : PaymentModel.fromFirestore(paymentDoc);
        if (_payment != null) {
          _reference.text = _payment!.transactionId;
          if (_payment!.transactionId.length >= 4) {
            _cardLast4.text = _payment!.transactionId.substring(_payment!.transactionId.length - 4);
          }
        }
      });
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return _showSnack('Please login again.');
    if (_application == null) return _showSnack('Submit an application first.');
    setState(() => _submitting = true);
    try {
      final ref = _reference.text.trim().isEmpty ? 'STRIPE-TEST-${DateTime.now().millisecondsSinceEpoch}' : _reference.text.trim();
      await _firestoreService.savePayment({
        'applicantId': uid,
        'applicationId': _application!.id,
        'amount': _application!.fee,
        'plotType': _application!.plotType,
        'paymentMethod': _method,
        'transactionId': ref,
        'cardLast4': _cardLast4.text.trim(),
        'receiptUrl': '',
        'status': 'submitted',
        'submittedAt': FieldValue.serverTimestamp(),
        'mode': 'test',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment submitted successfully.')));
      Navigator.pushReplacementNamed(context, AppConstants.ballotingRoute);
    } catch (e) {
      _showSnack('Payment record could not be saved. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final amount = _application?.fee ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Fee Payment'), actions: const [NotificationBell(), SizedBox(width: 8)]),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  _AmountCard(amount: amount, status: _payment?.status ?? 'not paid'),
                  const SizedBox(height: 16),
                  if (_application == null)
                    _NoApplicationCard()
                  else if (_payment != null)
                    _PaymentSubmittedCard(payment: _payment!, application: _application!)
                  else ...[
                    _StripeCard(),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Stripe Test Reference',
                      hint: 'STRIPE-TEST-123456',
                      controller: _reference,
                      prefixIcon: Icons.receipt_long_rounded,
                      validator: (v) => Validators.required(v, 'Stripe reference'),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Test Card Last 4',
                      hint: '4242',
                      controller: _cardLast4,
                      prefixIcon: Icons.credit_card_rounded,
                      keyboardType: TextInputType.number,
                      validator: (v) => Validators.required(v, 'Card last 4'),
                    ),
                    const SizedBox(height: 14),
                    _StripeHelp(),
                    const SizedBox(height: 18),
                    PrimaryGradientButton(text: 'Submit Payment', icon: Icons.lock_rounded, isLoading: _submitting, onPressed: _submit),
                  ],
                ],
              ),
            ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({required this.amount, required this.status});
  final int amount;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(28), boxShadow: AppColors.premiumShadow()),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.payments_rounded, color: AppColors.white, size: 34),
          const Spacer(),
          StatusBadge(text: status.toUpperCase(), type: badgeTypeFromStatus(status)),
        ]),
        const SizedBox(height: 16),
        Text('Application Fee', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white.withValues(alpha: .86))),
        const SizedBox(height: 4),
        Text(NumberFormat.currency(locale: 'en_PK', symbol: 'PKR ', decimalDigits: 0).format(amount), style: AppTextStyles.headingLarge.copyWith(color: AppColors.white)),
        const SizedBox(height: 8),
        Text('Stripe test mode is enabled for this applicant module.', style: AppTextStyles.captionText.copyWith(color: AppColors.white.withValues(alpha: .82))),
      ]),
    );
  }
}

class _StripeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderColor), boxShadow: AppColors.premiumShadow(opacity: .2)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 54, height: 54, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.credit_card_rounded, color: AppColors.white)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Stripe Test Mode', style: AppTextStyles.headingSmall),
          const SizedBox(height: 6),
          Text('Use test card 4242 4242 4242 4242, any future expiry date and any CVC.', style: AppTextStyles.bodyMedium),
        ])),
      ]),
    );
  }
}

class _StripeHelp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.infoLightBackground, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.infoBlue.withValues(alpha: .18))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.info_rounded, color: AppColors.infoBlue),
        const SizedBox(width: 10),
        Expanded(child: Text('After submission, payment status will be reviewed by society administration.', style: AppTextStyles.bodyMedium)),
      ]),
    );
  }
}

class _PaymentSubmittedCard extends StatelessWidget {
  const _PaymentSubmittedCard({required this.payment, required this.application});
  final PaymentModel payment;
  final ApplicationModel application;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderColor), boxShadow: AppColors.premiumShadow(opacity: .22)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const CircleAvatar(backgroundColor: AppColors.successLightBackground, child: Icon(Icons.check_rounded, color: AppColors.successGreen)),
          const SizedBox(width: 12),
          Expanded(child: Text('Payment Submitted', style: AppTextStyles.headingSmall)),
          StatusBadge(text: payment.status.toUpperCase(), type: badgeTypeFromStatus(payment.status)),
        ]),
        const SizedBox(height: 14),
        _row('Method', payment.paymentMethod.isEmpty ? 'Stripe Test Mode' : payment.paymentMethod),
        _row('Reference', payment.transactionId),
        _row('Plot Type', application.plotType),
        _row('Amount', NumberFormat.currency(locale: 'en_PK', symbol: 'PKR ', decimalDigits: 0).format(application.fee)),
        const SizedBox(height: 16),
        PrimaryGradientButton(text: 'Go to Balloting', icon: Icons.casino_rounded, onPressed: () => Navigator.pushReplacementNamed(context, AppConstants.ballotingRoute)),
      ]),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 110, child: Text(label, style: AppTextStyles.captionText)),
          Expanded(child: Text(value.isEmpty ? '-' : value, textAlign: TextAlign.right, style: AppTextStyles.labelBold)),
        ]),
      );
}

class _NoApplicationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderColor)),
      child: Column(children: [
        const Icon(Icons.description_outlined, size: 58, color: AppColors.hintText),
        const SizedBox(height: 12),
        Text('No application found', style: AppTextStyles.headingSmall),
        const SizedBox(height: 8),
        Text('Submit your application first, then add your payment record.', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 14),
        PrimaryGradientButton(text: 'Submit Application', onPressed: () => Navigator.pushReplacementNamed(context, AppConstants.applicationRoute)),
      ]),
    );
  }
}
