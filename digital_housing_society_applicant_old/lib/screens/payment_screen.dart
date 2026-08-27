import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/application_model.dart';
import '../models/payment_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_text_styles.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/header_actions.dart';
import '../widgets/illustrations.dart';
import '../widgets/status_badge.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _firestoreService = FirestoreService();
  final _storageService = StorageService();
  final _picker = ImagePicker();
  ApplicationModel? _application;
  PaymentModel? _payment;
  Map<String, dynamic>? _bankConfig;
  String? _method;
  File? _receipt;
  bool _loading = false;
  bool _pageLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final appDoc = await _firestoreService.getApplication(uid);
      final paymentDoc = await _firestoreService.getPayment(uid);
      final config = await _firestoreService.getPaymentConfig();
      setState(() {
        _application = appDoc == null ? null : ApplicationModel.fromFirestore(appDoc);
        _payment = paymentDoc == null ? null : PaymentModel.fromFirestore(paymentDoc);
        _bankConfig = config.exists ? (config.data() as Map<String, dynamic>) : FirestoreService.defaultPaymentConfig;
      });
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _pageLoading = false);
    }
  }

  Future<void> _pickReceipt() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 82);
    if (picked == null) return;
    final file = File(picked.path);
    if (await file.length() > 5 * 1024 * 1024) return _showSnack('Maximum receipt size is 5MB.');
    setState(() => _receipt = file);
  }

  Future<void> _submit() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return _showSnack('Please login again.');
    if (_application == null) return _showSnack('Submit your application first.');
    if (_method == null || _receipt == null) return _showSnack('Select method and upload receipt.');
    setState(() => _loading = true);
    try {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final receiptUrl = await _storageService.uploadImage(_receipt!, 'payments/$uid/receipt_$stamp.jpg');
      final transactionId = 'TXN-$stamp';
      await _firestoreService.savePayment({
        'applicantId': uid,
        'applicationId': _application!.id,
        'amount': _application!.fee,
        'plotType': _application!.plotType,
        'paymentMethod': _method,
        'receiptUrl': receiptUrl,
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'transactionId': transactionId,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment submitted for verification.')));
      await _load();
      if (!mounted) return;
      Navigator.pushNamed(context, AppConstants.ballotingRoute);
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment'), actions: const [NotificationBell(), SizedBox(width: 8)]),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
      body: _pageLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _FeeSummary(application: _application, payment: _payment),
                const SizedBox(height: 18),
                Text('Payment Method', style: AppTextStyles.headingSmall),
                const SizedBox(height: 12),
                _MethodTile(title: 'Bank Transfer', subtitle: _bankSubtitle(), icon: Icons.account_balance_rounded, selected: _method == 'Bank Transfer', color: AppColors.primaryPurple, onTap: () => setState(() => _method = 'Bank Transfer')),
                if (_method == 'Bank Transfer') _BankDetails(config: _bankConfig),
                _MethodTile(title: 'JazzCash', subtitle: 'Upload JazzCash transaction receipt', icon: Icons.phone_android_rounded, selected: _method == 'JazzCash', color: AppColors.warningOrange, onTap: () => setState(() => _method = 'JazzCash')),
                _MethodTile(title: 'EasyPaisa', subtitle: 'Upload EasyPaisa transaction receipt', icon: Icons.phone_iphone_rounded, selected: _method == 'EasyPaisa', color: AppColors.successGreen, onTap: () => setState(() => _method = 'EasyPaisa')),
                const SizedBox(height: 14),
                _ReceiptSection(receipt: _receipt, onTap: _pickReceipt),
                const SizedBox(height: 18),
                _Timeline(status: _payment?.status ?? 'awaiting'),
                const SizedBox(height: 18),
                PrimaryGradientButton(text: 'Submit Payment', onPressed: _method != null && _receipt != null ? _submit : null, isLoading: _loading),
              ],
            ),
    );
  }

  String _bankSubtitle() {
    if (_bankConfig == null) return 'HBL • Digital Housing Society';
    return '${_bankConfig!['bankName'] ?? 'HBL'} • ${_bankConfig!['accountTitle'] ?? 'Official Account'}';
  }
}

class _FeeSummary extends StatelessWidget {
  const _FeeSummary({required this.application, required this.payment});
  final ApplicationModel? application;
  final PaymentModel? payment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: AppColors.deepPurple, borderRadius: BorderRadius.circular(28), boxShadow: AppColors.premiumShadow()),
      child: Stack(
        children: [
          Positioned(right: -6, top: -6, child: SizedBox(width: 105, height: 105, child: CustomPaint(painter: ReceiptPainter()))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusBadge(text: payment?.status.toUpperCase() ?? 'AWAITING PAYMENT', type: badgeTypeFromStatus(payment?.status ?? 'awaiting')),
              const SizedBox(height: 18),
              Text('Fee Amount', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white.withValues(alpha: .8))),
              Text(NumberFormat.currency(locale: 'en_PK', symbol: 'PKR ', decimalDigits: 0).format(application?.fee ?? 0), style: AppTextStyles.headingLarge.copyWith(color: AppColors.gold)),
              const SizedBox(height: 8),
              Text('${application?.plotType ?? 'No plot selected'} • ${application?.serialNumber ?? 'No serial'}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white.withValues(alpha: .85))),
            ],
          ),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({required this.title, required this.subtitle, required this.icon, required this.selected, required this.color, required this.onTap});
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: selected ? AppColors.primaryPurple : AppColors.borderColor, width: selected ? 1.8 : 1), boxShadow: selected ? AppColors.premiumShadow(opacity: .24) : null),
      child: RadioListTile<String>(
        value: title,
        groupValue: selected ? title : null,
        onChanged: (_) => onTap(),
        activeColor: AppColors.primaryPurple,
        secondary: CircleAvatar(backgroundColor: color.withValues(alpha: .12), child: Icon(icon, color: color)),
        title: Text(title, style: AppTextStyles.labelBold),
        subtitle: Text(subtitle, style: AppTextStyles.captionText),
      ),
    );
  }
}

class _BankDetails extends StatelessWidget {
  const _BankDetails({required this.config});
  final Map<String, dynamic>? config;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.lightPurpleBackground, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('HBL Bank Details', style: AppTextStyles.labelBold),
        const SizedBox(height: 8),
        Text('Account Title: ${config?['accountTitle'] ?? FirestoreService.defaultPaymentConfig['accountTitle']}', style: AppTextStyles.bodyMedium),
        Text('Account Number: ${config?['accountNumber'] ?? FirestoreService.defaultPaymentConfig['accountNumber']}', style: AppTextStyles.bodyMedium),
        Text('IBAN: ${config?['iban'] ?? FirestoreService.defaultPaymentConfig['iban']}', style: AppTextStyles.bodyMedium),
      ]),
    );
  }
}

class _ReceiptSection extends StatelessWidget {
  const _ReceiptSection({required this.receipt, required this.onTap});
  final File? receipt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderColor), boxShadow: AppColors.premiumShadow(opacity: .22)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Upload Payment Receipt', style: AppTextStyles.headingSmall),
        const SizedBox(height: 12),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: receipt == null
              ? IllustrationBox(painter: ReceiptPainter(), height: 130, backgroundColor: AppColors.warningLightBackground)
              : ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(receipt!, height: 160, width: double.infinity, fit: BoxFit.cover)),
        ),
      ]),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final verified = s.contains('verified');
    final submitted = s.contains('pending') || verified;
    return Row(
      children: [
        _timeStep('Submitted', submitted, AppColors.successGreen),
        _line(submitted),
        _timeStep('Under Review', submitted && !verified, AppColors.warningOrange),
        _line(verified),
        _timeStep('Verified', verified, AppColors.successGreen),
      ],
    );
  }

  Widget _line(bool active) => Expanded(child: Container(height: 3, color: active ? AppColors.primaryPurple : AppColors.borderColor));

  Widget _timeStep(String label, bool active, Color color) => Column(children: [CircleAvatar(radius: 14, backgroundColor: active ? color : AppColors.borderColor, child: Icon(active ? Icons.check_rounded : Icons.more_horiz_rounded, size: 14, color: AppColors.white)), const SizedBox(height: 6), Text(label, style: AppTextStyles.captionText)]);
}
