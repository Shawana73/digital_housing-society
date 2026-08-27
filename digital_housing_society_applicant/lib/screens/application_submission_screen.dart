import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/applicant_model.dart';
import '../models/application_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_assets.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_text_styles.dart';
import '../utils/formatters_validators.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/branded_background.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/header_actions.dart';
import '../widgets/illustrations.dart';
import '../widgets/status_badge.dart';

class ApplicationSubmissionScreen extends StatefulWidget {
  const ApplicationSubmissionScreen({super.key});

  @override
  State<ApplicationSubmissionScreen> createState() => _ApplicationSubmissionScreenState();
}

class _ApplicationSubmissionScreenState extends State<ApplicationSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _fullName = TextEditingController();
  final _cnic = TextEditingController();
  final _contact = TextEditingController();
  final _address = TextEditingController();
  String? _plotType;
  String? _city;
  bool _declaration = false;
  bool _loading = false;
  bool _profileLoading = true;
  ApplicantModel? _applicant;
  ApplicationModel? _existingApplication;

  @override
  void initState() {
    super.initState();
    _loadApplicant();
  }

  @override
  void dispose() {
    _fullName.dispose();
    _cnic.dispose();
    _contact.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _loadApplicant() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await _firestoreService.getApplicant(uid);
      final appDoc = await _firestoreService.getApplication(uid);
      if (doc.exists) {
        final applicant = ApplicantModel.fromFirestore(doc);
        setState(() {
          _applicant = applicant;
          _fullName.text = applicant.fullName;
          _cnic.text = applicant.cnic;
          _contact.text = applicant.phone;
          _address.text = applicant.address;
          _city = AppConstants.pakistaniCities.contains(applicant.city) ? applicant.city : 'Other';
          _existingApplication = appDoc == null ? null : ApplicationModel.fromFirestore(appDoc);
        });
      } else {
        setState(() {
          _existingApplication = appDoc == null ? null : ApplicationModel.fromFirestore(appDoc);
        });
      }
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _profileLoading = false);
    }
  }

  String get _previewSerial => 'DHS-${DateTime.now().year}-XXXXX';
  int get _fee => _plotType == null ? 0 : AppConstants.plotFeeMap[_plotType!] ?? 0;

  String _generateSerial() {
    final number = Random.secure().nextInt(90000) + 10000;
    return 'DHS-${DateTime.now().year}-$number';
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_plotType == null) return _showSnack('Please select a plot type.');
    if (!_declaration) return _showSnack('Please confirm the declaration.');
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return _showSnack('Please login again.');
    setState(() => _loading = true);
    try {
      final serial = _generateSerial();
      await _firestoreService.updateApplicant(uid, {
        'fullName': _fullName.text.trim(),
        'cnic': _cnic.text.trim(),
        'phone': _contact.text.trim(),
        'address': _address.text.trim(),
        'city': _city,
      });
      await _firestoreService.saveApplication({
        'applicantId': uid,
        'fullName': _fullName.text.trim(),
        'cnic': _cnic.text.trim(),
        'plotType': _plotType,
        'fee': _fee,
        'contactNumber': _contact.text.trim(),
        'address': _address.text.trim(),
        'city': _city,
        'serialNumber': serial,
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Application Submitted'),
          content: Text('Your application serial number is $serial'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Continue'))],
        ),
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppConstants.uploadRoute);
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
      appBar: AppBar(title: const Text('Submit Application'), actions: [const NotificationBell(), Padding(padding: const EdgeInsets.only(right: 14), child: InitialsAvatar(name: _applicant?.fullName ?? 'Applicant'))]),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
      body: _profileLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
          : _existingApplication != null
              ? _SubmittedApplicationView(application: _existingApplication!)
              : BrandedImageBackground(
              imagePath: AppAssets.applyBackground,
              overlayOpacity: .22,
              child: Form(
              key: _formKey,
              onChanged: () => setState(() {}),
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(28), boxShadow: AppColors.premiumShadow()),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('New Application', style: AppTextStyles.headingMedium.copyWith(color: AppColors.white)),
                              const SizedBox(height: 6),
                              Text('Fill all required fields carefully', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white.withValues(alpha: .86))),
                              const SizedBox(height: 12),
                              StatusBadge(text: _previewSerial, type: StatusBadgeType.info),
                            ],
                          ),
                        ),
                        SizedBox(width: 104, height: 104, child: CustomPaint(painter: DocumentCheckPainter())),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppTextField(label: 'Full Name', hint: 'Enter full name', controller: _fullName, prefixIcon: Icons.person_rounded, validator: (v) => Validators.required(v, 'Full name')),
                  const SizedBox(height: 14),
                  AppTextField(label: 'CNIC', hint: '35202-1234567-8', controller: _cnic, prefixIcon: Icons.badge_rounded, keyboardType: TextInputType.number, inputFormatters: [CnicInputFormatter()], validator: Validators.cnic),
                  const SizedBox(height: 20),
                  Text('Select Plot Type', style: AppTextStyles.headingSmall),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = constraints.maxWidth < 420 ? (constraints.maxWidth - 8) / 2 : (constraints.maxWidth - 16) / 3;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        children: AppConstants.plotTypes
                            .map((type) => SizedBox(width: cardWidth, child: _PlotTypeCard(type: type, selected: _plotType == type, onTap: () => setState(() => _plotType = type))))
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.borderColor), boxShadow: AppColors.premiumShadow(opacity: .22)),
                    child: Row(
                      children: [
                        const Icon(Icons.payments_rounded, color: AppColors.warningOrange),
                        const SizedBox(width: 12),
                        Text('Fee Amount', style: AppTextStyles.labelBold),
                        const Spacer(),
                        Text(NumberFormat.currency(locale: 'en_PK', symbol: 'PKR ', decimalDigits: 0).format(_fee), style: AppTextStyles.headingSmall.copyWith(color: AppColors.deepPurple)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppTextField(label: 'Contact Number', hint: '03XX-XXXXXXX', controller: _contact, prefixIcon: Icons.phone_rounded, keyboardType: TextInputType.number, inputFormatters: [PakistaniPhoneFormatter()], validator: Validators.phone),
                  const SizedBox(height: 14),
                  AppTextField(label: 'Permanent Address', hint: 'Enter permanent address', controller: _address, prefixIcon: Icons.location_on_rounded, maxLines: 3, validator: (v) => Validators.required(v, 'Address')),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _city,
                    decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city_rounded)),
                    items: AppConstants.pakistaniCities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
                    onChanged: (value) => setState(() => _city = value),
                    validator: (v) => v == null || v.isEmpty ? 'City is required' : null,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.borderColor)),
                    child: CheckboxListTile(
                      value: _declaration,
                      onChanged: (value) => setState(() => _declaration = value ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text('I declare that all information provided is correct and accurate', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryText)),
                    ),
                  ),
                  const SizedBox(height: 22),
                  PrimaryGradientButton(text: 'Submit Application', onPressed: _submit, isLoading: _loading),
                ],
              ),
            ),
          ),
    );
  }
}


class _SubmittedApplicationView extends StatelessWidget {
  const _SubmittedApplicationView({required this.application});
  final ApplicationModel application;

  @override
  Widget build(BuildContext context) {
    return BrandedImageBackground(
      imagePath: AppAssets.applyBackground,
      overlayOpacity: .20,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: AppColors.premiumShadow(),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const CircleAvatar(radius: 28, backgroundColor: AppColors.white, child: Icon(Icons.check_rounded, color: AppColors.successGreen, size: 34)),
                const SizedBox(width: 14),
                Expanded(child: Text('Application Submitted', style: AppTextStyles.headingMedium.copyWith(color: AppColors.white))),
                StatusBadge(text: application.status.toUpperCase(), type: badgeTypeFromStatus(application.status)),
              ]),
              const SizedBox(height: 12),
              Text('Your application is saved in the system. You can continue with documents and payment.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white.withValues(alpha: .86))),
            ]),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderColor), boxShadow: AppColors.premiumShadow(opacity: .22)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Application Details', style: AppTextStyles.headingSmall),
              const SizedBox(height: 14),
              _detail('Application No.', application.serialNumber),
              _detail('Full Name', application.fullName),
              _detail('CNIC', application.cnic),
              _detail('Plot Type', application.plotType),
              _detail('City', application.city),
              _detail('Fee', NumberFormat.currency(locale: 'en_PK', symbol: 'PKR ', decimalDigits: 0).format(application.fee)),
            ]),
          ),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.pushReplacementNamed(context, AppConstants.uploadRoute), icon: const Icon(Icons.upload_file_rounded), label: const Text('Documents'))),
            const SizedBox(width: 12),
            Expanded(child: FilledButton.icon(onPressed: () => Navigator.pushReplacementNamed(context, AppConstants.paymentRoute), icon: const Icon(Icons.payment_rounded), label: const Text('Payment'))),
          ]),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 115, child: Text(label, style: AppTextStyles.captionText)),
        Expanded(child: Text(value.isEmpty ? '-' : value, textAlign: TextAlign.right, style: AppTextStyles.labelBold)),
      ]),
    );
  }
}

class _PlotTypeCard extends StatelessWidget {
  const _PlotTypeCard({required this.type, required this.selected, required this.onTap});
  final String type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fee = AppConstants.plotFeeMap[type] ?? 0;
    return AnimatedScale(
      scale: selected ? 1.04 : 1,
      duration: const Duration(milliseconds: 220),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.gold : AppColors.borderColor, width: selected ? 2 : 1),
            boxShadow: selected ? AppColors.premiumShadow(opacity: .32) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(type.startsWith('10') ? Icons.villa_rounded : Icons.house_rounded, color: AppColors.deepPurple),
              const SizedBox(height: 8),
              Text(type, style: AppTextStyles.labelBold, textAlign: TextAlign.center),
              const SizedBox(height: 5),
              Text('PKR ${NumberFormat.compact().format(fee)}', style: AppTextStyles.captionText, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
