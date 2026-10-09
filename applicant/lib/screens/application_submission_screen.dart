import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/applicant_model.dart';
import '../models/application_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../widgets/responsive_shell.dart';
import '../utils/app_text_styles.dart';
import '../utils/formatters_validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/header_actions.dart';
import '../widgets/status_badge.dart';
import '../widgets/batch3_ui.dart';

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
    if (uid == null) {
      if (mounted) setState(() => _profileLoading = false);
      return;
    }
    try {
      final doc = await _firestoreService.getApplicant(uid);
      final appDoc = await _firestoreService.getApplication(uid);
      if (!mounted) return;
      if (doc.exists) {
        final applicant = ApplicantModel.fromFirestore(doc);
        setState(() {
          _applicant = applicant;
          _fullName.text = applicant.fullName;
          _cnic.text = applicant.cnic;
          _contact.text = applicant.phone;
          _address.text = applicant.address;
          _city = applicant.city.trim().isEmpty ? null : applicant.city.trim();
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
      var actualSerial = serial;
      var savedHere = false;
      await _firestoreService.updateApplicant(uid, {
        'fullName': _fullName.text.trim(),
        'phone': _contact.text.trim(),
        'address': _address.text.trim(),
        'city': _city,
      });
      try {
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
        savedHere = true;
      } catch (e) {
        final existing = await _firestoreService.getApplication(uid);
        if (existing == null) rethrow;
        actualSerial = ApplicationModel.fromFirestore(existing).serialNumber;
        debugPrint('Application already saved; follow-up action failed: $e');
      }
      if (savedHere) {
        try {
        await FirebaseFirestore.instance.collection('activity_logs').add({
          'applicantId': uid,
          'action': 'Application submitted',
          'description':
              'Applicant submitted a housing application with serial number $serial.',
          'type': 'application',
          'timestamp': FieldValue.serverTimestamp(),
        });
        } catch (e) {
          debugPrint('Application activity log could not be written: $e');
        }
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Application Submitted'),
          content: Text('Your application serial number is $actualSerial'),
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

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >=
        DhsResponsiveShell.desktopBreakpoint;
    return DhsResponsiveShell(
      currentRoute: AppConstants.applicationRoute,
      mobileTitle: 'Applications',
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6FD),
        appBar: desktop ? AppBar(
          title: const Text('Housing Application'),
          backgroundColor: const Color(0xFFF8F6FD),
          foregroundColor: const Color(0xFF1E1B4B),
          titleTextStyle: const TextStyle(
            color: Color(0xFF1E1B4B),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ) : null,
        body: _profileLoading
            ? const Center(child: CircularProgressIndicator(
                color: AppColors.primaryPurple))
            : _existingApplication != null
                ? _SubmittedApplicationView(application: _existingApplication!)
                : Form(
                    key: _formKey,
                    onChanged: () => setState(() {}),
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(desktop ? 24 : 15, 18,
                          desktop ? 24 : 15, 30),
                      children: [DhsContentWidth(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const DhsPageBanner(
                            eyebrow: 'Applicant • New request',
                            title: 'Housing application',
                            subtitle: 'Your application number will be assigned '
                                'when you submit the completed form.',
                            icon: Icons.description_outlined,
                          ),
                          const SizedBox(height: 16),
                          DhsSection(
                            title: 'Applicant details',
                            subtitle: 'Confirm your personal information '
                                'before submitting.',
                            icon: Icons.person_outline_rounded,
                            child: Column(children: [
                              AppTextField(label: 'Full Name',
                                hint: 'Enter full name', controller: _fullName,
                                prefixIcon: Icons.person_rounded,
                                validator: Validators.fullName),
                              const SizedBox(height: 14),
                              AppTextField(label: 'CNIC',
                                hint: '35202-1234567-8', controller: _cnic,
                                prefixIcon: Icons.badge_rounded,
                                keyboardType: TextInputType.number,
                                readOnly: true,
                                inputFormatters: [CnicInputFormatter()],
                                validator: Validators.cnic),
                            ]),
                          ),
                          const SizedBox(height: 16),
                          DhsSection(
                            title: 'Choose a plot',
                            subtitle: 'The application fee updates '
                                'based on the selected plot type.',
                            icon: Icons.home_work_outlined,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                LayoutBuilder(builder: (context, constraints) {
                                  final columns = constraints.maxWidth >= 620
                                      ? 3 : constraints.maxWidth >= 380 ? 2 : 1;
                                  const spacing = 10.0;
                                  final cardWidth = (constraints.maxWidth -
                                      (columns - 1) * spacing) / columns;
                                  return Wrap(spacing: spacing, runSpacing: 10,
                                    children: AppConstants.plotTypes.map(
                                      (type) => SizedBox(width: cardWidth,
                                        child: _PlotTypeCard(
                                          type: type,
                                          selected: _plotType == type,
                                          onTap: () => setState(
                                              () => _plotType = type),
                                        ),
                                      ),
                                    ).toList(),
                                  );
                                }),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3EEFD),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Wrap(
                                    spacing: 12,
                                    runSpacing: 6,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    alignment: WrapAlignment.spaceBetween,
                                    children: [
                                      const Text('Application fee',
                                        style: TextStyle(fontWeight: FontWeight.w700,
                                            color: Color(0xFF53416B))),
                                      Text(NumberFormat.currency(locale: 'en_PK',
                                        symbol: 'PKR ', decimalDigits: 0)
                                          .format(_fee),
                                        style: const TextStyle(
                                          fontSize: 21, fontWeight: FontWeight.w900,
                                          color: Color(0xFF5132AB))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          DhsSection(
                            title: 'Contact & location',
                            subtitle: 'These details are saved with your application.',
                            icon: Icons.location_on_outlined,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppTextField(label: 'Contact Number',
                                  hint: '03XX-XXXXXXX', controller: _contact,
                                  prefixIcon: Icons.phone_rounded,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [PakistaniPhoneFormatter()],
                                  validator: Validators.phone),
                                const SizedBox(height: 14),
                                AppTextField(label: 'Permanent Address',
                                  hint: 'Enter permanent address',
                                  controller: _address,
                                  prefixIcon: Icons.location_on_rounded,
                                  maxLines: 3,
                                  validator: (v) => Validators.address(v)),
                                const SizedBox(height: 14),
                                const Text('City', style: TextStyle(
                                  color: AppColors.primaryText, fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                                const SizedBox(height: 7),
                                DropdownButtonFormField<String>(
                                  initialValue: _city,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    hintText: 'Select city',
                                    prefixIcon: Icon(Icons.location_city_rounded)),
                                  items: <String>{
                                    ...AppConstants.pakistaniCities,
                                    if (_city != null) _city!,
                                  }.map((city) => DropdownMenuItem(
                                      value: city, child: Text(city,
                                        overflow: TextOverflow.ellipsis)))
                                      .toList(),
                                  onChanged: (value) => setState(
                                      () => _city = value),
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'City is required' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          DhsSection(
                            title: 'Declaration',
                            icon: Icons.verified_user_outlined,
                            child: CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: _declaration,
                              onChanged: (value) => setState(
                                  () => _declaration = value ?? false),
                              title: const Text('I declare that all information '
                                  'provided is correct and accurate.'),
                            ),
                          ),
                          const SizedBox(height: 19),
                          PrimaryGradientButton(text: 'Submit Application',
                            icon: Icons.send_outlined,
                            onPressed: _submit, isLoading: _loading),
                        ],
                      ))],
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
    final desktop = MediaQuery.sizeOf(context).width >=
        DhsResponsiveShell.desktopBreakpoint;
    return ListView(
      padding: EdgeInsets.fromLTRB(desktop ? 24 : 15, 18,
          desktop ? 24 : 15, 30),
      children: [DhsContentWidth(child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DhsPageBanner(
            eyebrow: 'Saved application',
            title: 'Application details',
            subtitle: 'Your saved application details are shown below. '
                'Continue with your documents or payment below.',
            icon: Icons.assignment_turned_in_outlined,
            footer: Wrap(spacing: 10, runSpacing: 8, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(100)),
                child: Text(application.serialNumber.isEmpty
                      ? 'Number not available' : application.serialNumber,
                  style: const TextStyle(fontWeight: FontWeight.w800,
                    color: Colors.white, fontSize: 13)),
              ),
              StatusBadge(text: application.status.toUpperCase(),
                type: badgeTypeFromStatus(application.status)),
            ]),
          ),
          const SizedBox(height: 16),
          DhsSection(
            title: 'Your application',
            subtitle: 'Official values saved with your submission.',
            icon: Icons.list_alt_rounded,
            child: DhsDetailWrap(children: [
              DhsInfoBox(label: 'Application number',
                  value: application.serialNumber,
                  icon: Icons.tag_rounded),
              DhsInfoBox(label: 'Full name',
                  value: application.fullName,
                  icon: Icons.person_outline),
              DhsInfoBox(label: 'CNIC', value: application.cnic,
                  icon: Icons.badge_outlined),
              DhsInfoBox(label: 'Plot type', value: application.plotType,
                  icon: Icons.home_work_outlined),
              DhsInfoBox(label: 'City', value: application.city,
                  icon: Icons.location_city_outlined),
              DhsInfoBox(label: 'Application fee',
                  value: NumberFormat.currency(locale: 'en_PK',
                    symbol: 'PKR ', decimalDigits: 0).format(application.fee),
                  icon: Icons.payments_outlined),
            ]),
          ),
          const SizedBox(height: 16),
          DhsSection(title: 'Continue your application',
            subtitle: 'Open your documents or payment screen.',
            icon: Icons.route_outlined,
            child: LayoutBuilder(builder: (context, constraints) {
              final documents = OutlinedButton.icon(
                onPressed: () => Navigator.pushReplacementNamed(
                    context, AppConstants.uploadRoute),
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Documents'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15)),
              );
              final payment = DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF4B22D1),
                      Color(0xFF7C4DFF),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: FilledButton.icon(
                  onPressed: () => Navigator.pushReplacementNamed(
                      context, AppConstants.paymentRoute),
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Payment'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              );
              if (constraints.maxWidth < 390) {
                return Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [documents, const SizedBox(height: 10), payment]);
              }
              return Row(children: [
                Expanded(child: documents),
                const SizedBox(width: 11),
                Expanded(child: payment),
              ]);
            }),
          ),
        ],
      ))],
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
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? AppColors.gold : AppColors.borderColor, width: selected ? 2 : 1),
            boxShadow: selected ? AppColors.premiumShadow(opacity: .32) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(type.startsWith('10') ? Icons.villa_rounded : Icons.house_rounded, color: AppColors.deepPurple, size: 22),
              const SizedBox(height: 6),
              Text(
                type,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelBold.copyWith(fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              Text(
                'PKR ${NumberFormat.compact().format(fee)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.captionText.copyWith(fontSize: 10.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
