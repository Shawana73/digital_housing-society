import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/validators.dart';
import '../services/applicant_service.dart';
import '../widgets/app_text_field.dart';
import '../widgets/luxury_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/responsive_screen.dart';
import 'file_upload_screen.dart';

class ApplicationSubmissionScreen extends StatefulWidget {
  const ApplicationSubmissionScreen({super.key});
  static const routeName = '/submit-application';

  @override
  State<ApplicationSubmissionScreen> createState() => _ApplicationSubmissionScreenState();
}

class _ApplicationSubmissionScreenState extends State<ApplicationSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _cnic = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _preference = TextEditingController();
  String _plotSize = '5 Marla';
  String _plotType = 'Residential';
  bool _loading = false;
  bool _prefilled = false;

  Future<void> _prefill() async {
    if (_prefilled) return;
    _prefilled = true;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await FirebaseFirestore.instance.collection('applicants').doc(uid).get();
    final data = snap.data();
    if (data == null || !mounted) return;
    _fullName.text = data['fullName'] ?? '';
    _cnic.text = data['cnic'] ?? '';
    _phone.text = data['phone'] ?? '';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ApplicantService.submitApplication(
        fullName: _fullName.text.trim(),
        cnic: _cnic.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        plotSize: _plotSize,
        plotType: _plotType,
        preference: _preference.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application submitted successfully.')));
      Navigator.pushReplacementNamed(context, FileUploadScreen.routeName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _fullName.dispose();
    _cnic.dispose();
    _phone.dispose();
    _address.dispose();
    _preference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _prefill();
    return ResponsiveScreen(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
            const SizedBox(height: 10),
            const Text('APPLICATION\nSUBMISSION', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.primaryText, height: 1.1)),
            const SizedBox(height: 8),
            const Text('Submit personal details and plot preference. System generates application file/number automatically; applicant does not upload application file manually.', style: TextStyle(color: AppColors.secondaryText, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            LuxuryCard(
              child: Column(
                children: [
                  AppTextField(label: 'Full Name', controller: _fullName, validator: (v) => Validators.requiredText(v, 'Full name')),
                  const SizedBox(height: 16),
                  AppTextField(label: 'CNIC', controller: _cnic, hintText: '42101-1234567-1', validator: Validators.cnic),
                  const SizedBox(height: 16),
                  AppTextField(label: 'Contact Info', controller: _phone, hintText: '03001234567', validator: Validators.phone),
                  const SizedBox(height: 16),
                  AppTextField(label: 'Address', controller: _address, maxLines: 2, validator: (v) => Validators.requiredText(v, 'Address')),
                  const SizedBox(height: 16),
                  _LuxuryDropdown(label: 'Plot Type', value: _plotType, items: const ['Residential', 'Commercial'], onChanged: (v) => setState(() => _plotType = v!)),
                  const SizedBox(height: 16),
                  _LuxuryDropdown(label: 'Plot Size', value: _plotSize, items: const ['3 Marla', '5 Marla', '10 Marla', '1 Kanal'], onChanged: (v) => setState(() => _plotSize = v!)),
                  const SizedBox(height: 16),
                  AppTextField(label: 'Preferred Block / Notes', controller: _preference, hintText: 'e.g. A Block preferred, near park, corner plot if available'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.lightPurple.withOpacity(0.45), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.lavender)),
                    child: const Text(
                      'Application file means the system-generated application record/number after form submission. It is not a separate file that applicant uploads.',
                      style: TextStyle(color: AppColors.secondaryText, fontWeight: FontWeight.w700, height: 1.35),
                    ),
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(text: 'SUBMIT APPLICATION', icon: Icons.assignment_turned_in_rounded, loading: _loading, onPressed: _submit),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LuxuryDropdown extends StatelessWidget {
  const _LuxuryDropdown({required this.label, required this.value, required this.items, required this.onChanged});

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(label.toUpperCase(), style: const TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
        ),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.home_work_rounded, color: AppColors.primaryPurple)),
        ),
      ],
    );
  }
}
