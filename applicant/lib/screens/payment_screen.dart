import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/application_model.dart';
import '../models/payment_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../widgets/responsive_shell.dart';
import '../utils/formatters_validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/status_badge.dart';
import '../widgets/batch3_ui.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final _cardLast4 = TextEditingController(text: '4242');
  static const String _method = 'Stripe Test Mode';
  ApplicationModel? _application;
  PaymentModel? _payment;
  bool _loading = true;
  bool _submitting = false;
  final StorageService _storageService = StorageService();
  XFile? _receiptImage;
  bool _uploadingReceipt = false;

  Future<void> _pickReceipt() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image == null || !mounted) return;
      setState(() => _receiptImage = image);
    } catch (e) {
      debugPrint('Receipt picker error: $e');
      if (mounted) _showSnack('Receipt could not be selected. Please try again.');
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _cardLast4.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final applicationDoc = await _firestoreService.getApplication(uid);
      final paymentDoc = await _firestoreService.getPayment(uid);
      if (!mounted) return;
      setState(() {
        _application =
        applicationDoc == null ? null : ApplicationModel.fromFirestore(
            applicationDoc);
        _payment =
        paymentDoc == null ? null : PaymentModel.fromFirestore(paymentDoc);
        if (_payment != null) {
          if (_payment!.transactionId.length >= 4) {
            _cardLast4.text = _payment!.transactionId.substring(
                _payment!.transactionId.length - 4);
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
      final ref = 'STRIPE-TEST-${DateTime
          .now()
          .millisecondsSinceEpoch}';

      if (_receiptImage == null) {
        _showSnack('Please select a payment receipt image.');
        return;
      }

      setState(() => _uploadingReceipt = true);

      final receiptBytes = await _receiptImage!.readAsBytes();

      final receiptUrl = await _storageService.uploadImage(
        receiptBytes,
        'payment_receipt_${uid}_${DateTime
            .now()
            .millisecondsSinceEpoch}.jpg',
      );

      final paymentData = {
        'applicantId': uid,
        'applicationId': _application!.id,
        'amount': _application!.fee,
        'plotType': _application!.plotType,
        'paymentMethod': _method,
        'transactionId': ref,
        'cardLast4': _cardLast4.text.trim(),
        'receiptUrl': receiptUrl,
        'status': 'submitted',
        'submittedAt': FieldValue.serverTimestamp(),
        'mode': 'test',
      };
      // A notification may fail after the payment record was committed.
      // Check for that record before inviting an accidental duplicate retry.
      var savedHere = false;
      try {
        await _firestoreService.savePayment(paymentData);
        savedHere = true;
      } catch (e) {
        final existing = await _firestoreService.getPayment(uid);
        if (existing == null) rethrow;
        debugPrint('Payment already saved; follow-up action failed: $e');
      }
      // An optional activity log must not turn a committed payment into a
      // misleading failure or encourage a second submission.
      if (savedHere) {
        try {
        await FirebaseFirestore.instance.collection('activity_logs').add({
          'applicantId': uid,
          'action': 'Payment submitted',
          'description': 'Applicant submitted a payment of PKR ${_application!.fee}.',
          'type': 'payment',
          'timestamp': FieldValue.serverTimestamp(),
        });
        } catch (e) {
          debugPrint('Payment activity log could not be written: $e');
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment submitted successfully.')));
      Navigator.pushReplacementNamed(context, AppConstants.ballotingRoute);
    } catch (e) {
      _showSnack('Payment record could not be saved. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          _uploadingReceipt = false;
        });
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final amount = _application?.fee ?? 0;
    final desktop = MediaQuery.sizeOf(context).width >=
        DhsResponsiveShell.desktopBreakpoint;

    return DhsResponsiveShell(
      currentRoute: AppConstants.paymentRoute,
      mobileTitle: 'Payments',
      showMobileNotification: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6FD),
        appBar: desktop
            ? AppBar(
                title: const Text(
                  'Fee Payment',
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                backgroundColor: const Color(0xFFF8F6FD),
                foregroundColor: AppColors.primaryText,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
              )
            : null,
        body: _loading
            ? const Center(child: CircularProgressIndicator(
                color: AppColors.primaryPurple))
            : Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(desktop ? 24 : 15, 18,
                      desktop ? 24 : 15, 30),
                  children: [
                    DhsContentWidth(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DhsPageBanner(
                          eyebrow: 'Application payment',
                          title: 'Fee & receipt',
                          subtitle: 'Review the amount from your application, then '
                              'submit a test payment record for admin review.',
                          icon: Icons.account_balance_wallet_outlined,
                          footer: Wrap(spacing: 9, runSpacing: 8, children: [
                            const _LightChip(text: 'TEST MODE',
                                icon: Icons.science_outlined),
                            _LightChip(
                              text: _application?.plotType ?? 'Application required',
                              icon: Icons.home_work_outlined,
                            ),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        _AmountCard(
                          amount: amount,
                          status: _payment?.status ?? 'not submitted',
                          serial: _application?.serialNumber,
                        ),
                        const SizedBox(height: 16),
                        if (_application == null)
                          const _NoApplicationCard()
                        else if (_payment != null)
                          _PaymentSubmittedCard(
                            payment: _payment!, application: _application!)
                        else ...[
                          DhsSection(
                            title: 'Test payment details',
                            subtitle: 'This records a Stripe test-mode reference. '
                                'It does not charge a real card.',
                            icon: Icons.credit_card_outlined,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _StripeCard(),
                                const SizedBox(height: 18),
                                AppTextField(
                                  label: 'Test Card Last 4',
                                  hint: '4242',
                                  controller: _cardLast4,
                                  prefixIcon: Icons.credit_card_rounded,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [DigitsOnlyLengthFormatter(4)],
                                  validator: (v) => Validators.fixedDigits(
                                      v, 'Card last 4', 4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          DhsSection(
                            title: 'Payment receipt',
                            subtitle: 'Choose a receipt image before submitting '
                                'the payment record.',
                            icon: Icons.receipt_long_outlined,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(17),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F4FE),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFD9CCF0),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Column(children: [
                                    const Icon(Icons.cloud_upload_outlined,
                                        size: 34, color: Color(0xFF6C4BB2)),
                                    const SizedBox(height: 7),
                                    Text(
                                      _receiptImage == null
                                          ? 'No receipt selected'
                                          : _receiptImage!.name,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF34274D),
                                      ),
                                    ),
                                    const SizedBox(height: 13),
                                    OutlinedButton.icon(
                                      onPressed: _uploadingReceipt || _submitting
                                          ? null : _pickReceipt,
                                      icon: const Icon(Icons.image_outlined),
                                      label: Text(_receiptImage == null
                                          ? 'Select receipt' : 'Change receipt'),
                                    ),
                                  ]),
                                ),
                                const SizedBox(height: 14),
                                const _StripeHelp(),
                                const SizedBox(height: 19),
                                PrimaryGradientButton(
                                  text: _uploadingReceipt
                                      ? 'Uploading receipt...'
                                      : 'Submit payment record',
                                  icon: Icons.lock_outline_rounded,
                                  isLoading: _submitting,
                                  onPressed: _submitting ? null : _submit,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    )),
                  ],
                ),
              ),
      ),
    );
  }
}

class _LightChip extends StatelessWidget {
  const _LightChip({required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 320),
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .17),
      borderRadius: BorderRadius.circular(100),
      border: Border.all(color: Colors.white30),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white, size: 15),
      const SizedBox(width: 6),
      Flexible(child: Text(text, maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 11.5,
              fontWeight: FontWeight.w700))),
    ]),
  );
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({required this.amount, required this.status, this.serial});
  final int amount;
  final String status;
  final String? serial;

  @override
  Widget build(BuildContext context) => DhsSection(
    title: 'Application fee',
    subtitle: 'Amount comes from your saved application.',
    icon: Icons.payments_outlined,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        NumberFormat.currency(locale: 'en_PK', symbol: 'PKR ',
            decimalDigits: 0).format(amount),
        style: const TextStyle(fontSize: 29,
            color: Color(0xFF4F32A5), fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 12),
      Wrap(spacing: 9, runSpacing: 9, children: [
        StatusBadge(text: status.toUpperCase(),
            type: badgeTypeFromStatus(status)),
        if (serial != null && serial!.trim().isNotEmpty)
          _ReferencePill(text: serial!),
      ]),
    ]),
  );
}

class _ReferencePill extends StatelessWidget {
  const _ReferencePill({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFFF0EDF9),
      borderRadius: BorderRadius.circular(100),
    ),
    child: Text(text, style: const TextStyle(
      fontSize: 12, fontWeight: FontWeight.w700,
      color: Color(0xFF60469A),
    )),
  );
}

class _StripeCard extends StatelessWidget {
  const _StripeCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8F6FC),
      borderRadius: BorderRadius.circular(15),
    ),
    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.science_outlined, color: Color(0xFF6547A7), size: 23),
      SizedBox(width: 11),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stripe test mode', style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w800,
            color: Color(0xFF302244),
          )),
          SizedBox(height: 5),
          Text('Test card example: 4242 4242 4242 4242, '
              'any future expiry and CVC. No live charge is made.',
            style: TextStyle(fontSize: 12.5,
                height: 1.4, color: Color(0xFF675C76))),
        ],
      )),
    ]),
  );
}

class _StripeHelp extends StatelessWidget {
  const _StripeHelp();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F7FF),
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.info_outline_rounded, size: 20,
          color: Color(0xFF4469A7)),
      SizedBox(width: 9),
      Expanded(child: Text(
        'After you submit, your receipt and payment record are sent '
        'for society administration review. This does not confirm approval.',
        style: TextStyle(color: Color(0xFF3E5677), height: 1.4,
          fontSize: 12.5),
      )),
    ]),
  );
}

class _PaymentSubmittedCard extends StatelessWidget {
  const _PaymentSubmittedCard({required this.payment,
      required this.application});
  final PaymentModel payment;
  final ApplicationModel application;

  @override
  Widget build(BuildContext context) => DhsSection(
    title: 'Payment record submitted',
    subtitle: 'The saved status below is controlled by your backend '
        'and may change after administration review.',
    icon: Icons.fact_check_outlined,
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(alignment: Alignment.centerLeft,
          child: StatusBadge(text: payment.status.toUpperCase(),
            type: badgeTypeFromStatus(payment.status))),
        const SizedBox(height: 15),
        DhsDetailWrap(children: [
          DhsInfoBox(label: 'Payment method',
            value: payment.paymentMethod.isEmpty
                ? 'Stripe Test Mode' : payment.paymentMethod),
          DhsInfoBox(label: 'Reference', value: payment.transactionId),
          DhsInfoBox(label: 'Plot type', value: application.plotType),
          DhsInfoBox(label: 'Submitted amount',
            value: NumberFormat.currency(locale: 'en_PK',
                symbol: 'PKR ', decimalDigits: 0).format(payment.amount)),
        ]),
        const SizedBox(height: 18),
        PrimaryGradientButton(text: 'Go to Balloting',
          icon: Icons.casino_outlined,
          onPressed: () => Navigator.pushReplacementNamed(
              context, AppConstants.ballotingRoute)),
      ],
    ),
  );
}

class _NoApplicationCard extends StatelessWidget {
  const _NoApplicationCard();
  @override
  Widget build(BuildContext context) => DhsSection(
    title: 'Application required',
    subtitle: 'Submit an application first to see its actual fee.',
    icon: Icons.description_outlined,
    child: PrimaryGradientButton(text: 'Submit Application',
      onPressed: () => Navigator.pushReplacementNamed(
          context, AppConstants.applicationRoute)),
  );
}
