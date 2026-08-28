import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/app_assets.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_text_styles.dart';
import '../utils/formatters_validators.dart';
import '../widgets/branded_background.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKeys = List.generate(3, (_) => GlobalKey<FormState>());
  final _pageController = PageController();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  final _fullName = TextEditingController();
  final _cnic = TextEditingController();
  final _dob = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();

  DateTime? _dobValue;
  int _step = 0;
  bool _declaration = false;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _pageController.dispose();
    _fullName.dispose();
    _cnic.dispose();
    _dob.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _address.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1940),
      lastDate: now,
    );
    if (date == null) return;
    setState(() {
      _dobValue = date;
      _dob.text = '${date.day}/${date.month}/${date.year}';
    });
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (!_formKeys[_step].currentState!.validate()) return;
    if (_step < 2) {
      setState(() => _step++);
      _pageController.animateToPage(_step, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.pop(context);
    } else {
      setState(() => _step--);
      _pageController.animateToPage(_step, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    }
  }

  Future<void> _submit() async {
    if (!_declaration) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please confirm the declaration.')));
      return;
    }
    setState(() => _loading = true);
    try {
      final credential = await _authService.register(_email.text, _password.text);
      final uid = credential.user!.uid;
      await credential.user!.updateDisplayName(_fullName.text.trim());
      await _firestoreService.saveApplicant({
        'uid': uid,
        'fullName': _fullName.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'cnic': _cnic.text.trim(),
        'dateOfBirth': Timestamp.fromDate(_dobValue!),
        'address': _address.text.trim(),
        'city': _city.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'profileStatus': 'active',
        'notificationsEnabled': true,
        'ballotingRegistered': false,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration completed successfully.')));
      Navigator.pushNamedAndRemoveUntil(context, AppConstants.dashboardRoute, (_) => false);
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? e.code);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  double get _strength {
    final p = _password.text;
    var score = 0.0;
    if (p.length >= 8) score += .34;
    if (RegExp(r'[A-Z]').hasMatch(p)) score += .33;
    if (RegExp(r'\d').hasMatch(p)) score += .33;
    return score.clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account'), leading: IconButton(onPressed: _back, icon: const Icon(Icons.arrow_back_rounded))),
      body: BrandedImageBackground(
        imagePath: AppAssets.courtyardBackground,
        overlayOpacity: .56,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: .96),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: AppColors.darkNavy.withValues(alpha: .14), blurRadius: 24, offset: const Offset(0, 14))],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(22),
                    child: _StepIndicator(currentStep: _step),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [_personalStep(), _securityStep(), _addressStep()],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(22),
                    child: PrimaryGradientButton(text: _step == 2 ? 'Submit Registration' : 'Continue', onPressed: _next, isLoading: _loading),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _personalStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Form(
        key: _formKeys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Personal Info', style: AppTextStyles.headingLarge),
            const SizedBox(height: 8),
            Text('Enter accurate personal details for your application profile.', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 24),
            AppTextField(label: 'Full Name', hint: 'Enter full name', controller: _fullName, prefixIcon: Icons.person_rounded, validator: (v) => Validators.required(v, 'Full name')),
            const SizedBox(height: 16),
            AppTextField(
              label: 'CNIC',
              hint: '35202-1234567-8',
              controller: _cnic,
              prefixIcon: Icons.badge_rounded,
              keyboardType: TextInputType.number,
              inputFormatters: [CnicInputFormatter()],
              validator: Validators.cnic,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Date of Birth',
              hint: 'Select date',
              controller: _dob,
              prefixIcon: Icons.calendar_month_rounded,
              readOnly: true,
              onTap: _pickDate,
              validator: (v) => _dobValue == null ? 'Date of birth is required' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _securityStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Form(
        key: _formKeys[1],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact & Security', style: AppTextStyles.headingLarge),
            const SizedBox(height: 8),
            Text('Your login credentials and contact details.', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 24),
            AppTextField(label: 'Email', hint: 'you@example.com', controller: _email, prefixIcon: Icons.email_rounded, keyboardType: TextInputType.emailAddress, validator: Validators.email),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Phone',
              hint: '03XX-XXXXXXX',
              controller: _phone,
              prefixIcon: Icons.phone_rounded,
              keyboardType: TextInputType.number,
              inputFormatters: [PakistaniPhoneFormatter()],
              validator: Validators.phone,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Password',
              hint: 'Minimum 8 chars, uppercase, number',
              controller: _password,
              prefixIcon: Icons.lock_rounded,
              obscureText: _obscurePassword,
              validator: Validators.password,
              onChanged: (_) => setState(() {}),
              suffix: IconButton(onPressed: () => setState(() => _obscurePassword = !_obscurePassword), icon: Icon(_obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded)),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(value: _strength, minHeight: 8, color: AppColors.primaryPurple, backgroundColor: AppColors.lightPurpleBackground),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Confirm Password',
              hint: 'Repeat password',
              controller: _confirmPassword,
              prefixIcon: Icons.verified_user_rounded,
              obscureText: _obscureConfirm,
              validator: (v) => v != _password.text ? 'Passwords do not match' : null,
              suffix: IconButton(onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm), icon: Icon(_obscureConfirm ? Icons.visibility_rounded : Icons.visibility_off_rounded)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addressStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Form(
        key: _formKeys[2],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Address & Confirm', style: AppTextStyles.headingLarge),
            const SizedBox(height: 8),
            Text('Confirm your city and declaration before submitting.', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 24),
            AppTextField(label: 'Street Address', hint: 'House, street, area', controller: _address, prefixIcon: Icons.location_on_rounded, maxLines: 3, validator: (v) => Validators.required(v, 'Address')),
            const SizedBox(height: 16),
            AppTextField(label: 'City', hint: 'Enter city', controller: _city, prefixIcon: Icons.location_city_rounded, validator: (v) => Validators.required(v, 'City')),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.borderColor)),
              child: CheckboxListTile(
                value: _declaration,
                onChanged: (value) => setState(() => _declaration = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text('I confirm all information is correct and accurate', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryText)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        final active = index <= currentStep;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
            height: 8,
            decoration: BoxDecoration(
              color: active ? AppColors.primaryPurple : AppColors.lightPurpleBackground,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );
      }),
    );
  }
}
