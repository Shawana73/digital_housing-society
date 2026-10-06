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
  // Keep a newly created Auth account attached to this form if a later
  // Firestore or verification-email operation fails. Submit retries must not
  // call createUserWithEmailAndPassword again for that same account.
  String? _registrationUid;
  String? _registrationEmail;
  bool _profileSaved = false;

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
    if (_loading) return;
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


  Future<void> _sendVerificationEmail(User user) async {
    await user.sendEmailVerification();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Email Verification Required'),
        content: Text('A verification link has been sent to ${user.email}. Please verify your email first, then login to continue.'),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Go to Login')),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_declaration) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please confirm the declaration.')));
      return;
    }
    setState(() => _loading = true);
    var stage = 'opening your registration account';
    try {
      User user;
      if (_registrationUid == null) {
        final enteredEmail = _email.text.trim().toLowerCase();
        final signedIn = _authService.currentUser;
        // A failed Firestore save may have already CREATED this Auth user.
        // Resuming the signed-in unverified user avoids creating a second UID
        // and makes a browser refresh / reopening registration recoverable.
        if (signedIn != null &&
            signedIn.email?.trim().toLowerCase() == enteredEmail) {
          if (signedIn.emailVerified) {
            throw StateError(
              'This account is already email-verified. Please sign in instead.',
            );
          }
          user = signedIn;
        } else if (signedIn != null) {
          throw StateError(
            'A different account is currently signed in. Sign out of that '
            'account before starting this registration.',
          );
        } else {
          stage = 'creating or recovering your account';
          try {
            final credential =
                await _authService.register(_email.text, _password.text);
            if (credential.user == null) {
              throw StateError('Could not open your registration account.');
            }
            user = credential.user!;
          } on FirebaseAuthException catch (error) {
            if (error.code != 'email-already-in-use') rethrow;
            // An earlier app run can have created Auth successfully but
            // stopped before the profile write. Only somebody who knows the
            // existing password can resume it; NEVER delete an account.
            stage = 'recovering an earlier registration';
            final recovered =
                await _authService.login(_email.text, _password.text);
            if (recovered.user == null) {
              throw StateError('Could not recover your existing account.');
            }
            if (recovered.user!.emailVerified) {
              throw StateError(
                'This email already has a verified account. Please use Login.',
              );
            }
            user = recovered.user!;
          }
        }
        _registrationUid = user.uid;
        _registrationEmail = user.email?.trim().toLowerCase();
      } else {
        if (_email.text.trim().toLowerCase() != _registrationEmail) {
          throw StateError(
            'This account was created with a different email. Restore the '
            'original email to retry, or contact DHS support.',
          );
        }
        // A failed save or email delivery should be recoverable by pressing
        // Submit again, even if the SDK has lost the in-memory auth session.
        final current = _authService.currentUser;
        if (current?.uid == _registrationUid) {
          user = current!;
        } else {
          final recovered =
              await _authService.login(_email.text, _password.text);
          if (recovered.user?.uid != _registrationUid) {
            throw StateError(
              'The previous account could not be recovered. Contact DHS support.',
            );
          }
          user = recovered.user!;
        }
      }
      final uid = user.uid;
      if (!_profileSaved) {
        stage = 'saving your applicant profile';
        await _firestoreService.saveApplicant({
          'uid': uid,
          'fullName': _fullName.text.trim(),
          'email': _email.text.trim(),
          'phone': _phone.text.trim(),
          'cnic': _cnic.text.trim(),
          'cnicDigits': _cnic.text.replaceAll(RegExp(r'\D'), ''),
          'dateOfBirth': Timestamp.fromDate(_dobValue!),
          'address': _address.text.trim(),
          'city': _city.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'profileStatus': 'email verification pending',
          'notificationsEnabled': true,
          'ballotingRegistered': false,
          'emailVerified': false,
        });
        _profileSaved = true;
        // Display-name update isn't critical to the Firestore profile.
        try {
          await user.updateDisplayName(_fullName.text.trim());
        } catch (error, stack) {
          debugPrint('DHS registration display-name update: $error');
          debugPrintStack(stackTrace: stack);
        }
      }
      stage = 'sending your verification email';
      await _sendVerificationEmail(user);
      stage = 'signing out after registration';
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppConstants.loginRoute, (_) => false);
    } on FirebaseAuthException catch (e) {
      debugPrint('DHS registration [$stage] Auth error: ${e.code}');
      _showError(_registrationError(stage, e.code));
    } on FirebaseException catch (e, stack) {
      debugPrint('DHS registration [$stage] Firebase error: ${e.code}');
      debugPrintStack(stackTrace: stack);
      _showError(_registrationError(stage, e.code));
    } catch (error, stack) {
      debugPrint('DHS registration [$stage] ${error.runtimeType}: $error');
      debugPrintStack(stackTrace: stack);
      if (error is StateError &&
          (error.message.contains('CNIC') ||
              error.message.contains('account') ||
              error.message.contains('email') ||
              error.message.contains('login session'))) {
        _showError(error.message);
      } else {
        _showError(
          'Registration stopped while $stage (${error.runtimeType}). '
          'Your account was not deleted. If Retry still fails, please send '
          'DHS support this stage and the error shown in the Chrome console.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _registrationError(String stage, String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email already has an account. Please sign in instead. '
            'If an earlier registration stopped midway, contact DHS support.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'network-request-failed':
      case 'unavailable':
        return 'Network unavailable while $stage. Check your internet and '
            'try Submit again; an account already created will be preserved.';
      case 'permission-denied':
        return 'Firestore rejected the request while $stage. Your account '
            'has not been deleted. Please contact DHS support to check the '
            'deployed database rules (permission-denied).';
      case 'too-many-requests':
        return 'Too many attempts. Please wait before trying again.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'This email may already have an account with a different '
            'password. Try Login or Forgot Password instead of creating '
            'another account.';
      default:
        return 'Could not finish $stage ($code). Please try Submit again. '
            'No existing account has been deleted.';
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 9),
      ));
  }

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
    final desktopScreen = MediaQuery.sizeOf(context).width >= 860;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1FF),
      // The desktop AppBar was an otherwise empty white horizontal stripe
      // above the registration panel. Mobile retains its existing back bar.
      appBar: desktopScreen ? null : AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryText,
        leading: IconButton(
          onPressed: _back,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 860;
            if (desktop) {
              final panelHeight =
                  (constraints.maxHeight - 28).clamp(560.0, 740.0).toDouble();
              return SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1130),
                    child: SizedBox(
                      height: panelHeight,
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.deepPurple.withValues(alpha: .14),
                              blurRadius: 30,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 9,
                              child: _registrationImagePanel(compact: false),
                            ),
                            Expanded(
                              flex: 11,
                              child: _registrationCard(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            // Mobile keeps the photography as a short header so the form
            // and its validation messages have the available screen height.
            final photoHeight = constraints.maxHeight < 570 ? 86.0 : 134.0;
            return Column(
              children: [
                SizedBox(
                  height: photoHeight,
                  width: double.infinity,
                  child: _registrationImagePanel(compact: true),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: _registrationCard(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _registrationImagePanel({required bool compact}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AppAssets.registrationBackground,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
        ),
        // Subtle purple photo tint is requested ONLY on registration.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF3D226B).withValues(alpha: .13),
                const Color(0xFF201737).withValues(alpha: compact ? .57 : .72),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(compact ? 17 : 34),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                compact ? 'Your journey starts here' : 'Welcome to DHS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 20 : 32,
                  height: 1.15,
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: 12),
                const Text(
                  'Build your applicant profile and discover a better way to manage your future home.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _registrationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7DEFA)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (MediaQuery.sizeOf(context).width >= 860)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _loading ? null : _back,
                      icon: const Icon(Icons.arrow_back_rounded, size: 17),
                      label: const Text('Back'),
                    ),
                  ),
                Text(
                  'Applicant Registration',
                  style: AppTextStyles.headingMedium.copyWith(
                    color: AppColors.deepPurple,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Step ${_step + 1} of 3',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 14),
                _StepIndicator(currentStep: _step),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _personalStep(),
                _securityStep(),
                _addressStep(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 17),
            child: PrimaryGradientButton(
              text: _step == 2 ? 'Submit Registration' : 'Continue',
              onPressed: _next,
              isLoading: _loading,
            ),
          ),
        ],
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
            AppTextField(label: 'Full Name', hint: 'Enter full name', controller: _fullName, prefixIcon: Icons.person_rounded, validator: Validators.fullName),
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
            AppTextField(label: 'Street Address', hint: 'House, street, area', controller: _address, prefixIcon: Icons.location_on_rounded, maxLines: 3, validator: (v) => Validators.address(v)),
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
