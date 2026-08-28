import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_assets.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_text_styles.dart';
import '../utils/formatters_validators.dart';
import '../widgets/branded_background.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _authService.resetPassword(_emailController.text);
      if (!mounted) return;
      setState(() => _sent = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset link sent successfully.')));
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? e.code);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BrandedImageBackground(
        imagePath: AppAssets.profileBackground,
        overlayOpacity: .66,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 44),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 430),
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: .96),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [BoxShadow(color: AppColors.darkNavy.withValues(alpha: .16), blurRadius: 28, offset: const Offset(0, 18))],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(AppAssets.logo, width: 135, fit: BoxFit.contain),
                            const SizedBox(height: 18),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              width: 82,
                              height: 82,
                              decoration: BoxDecoration(
                                gradient: _sent ? null : AppColors.primaryGradient,
                                color: _sent ? AppColors.successGreen : null,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: AppColors.premiumShadow(opacity: .28),
                              ),
                              child: Icon(_sent ? Icons.check_rounded : Icons.mark_email_unread_rounded, color: AppColors.white, size: 42),
                            ),
                            const SizedBox(height: 20),
                            Text(_sent ? 'Check Your Email' : 'Reset Password', style: AppTextStyles.headingLarge, textAlign: TextAlign.center),
                            const SizedBox(height: 8),
                            Text(
                              _sent ? 'We have sent a secure reset link to your email.' : 'Enter your email and we will send you a password reset link.',
                              style: AppTextStyles.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            AppTextField(
                              label: 'Email Address',
                              hint: 'you@example.com',
                              controller: _emailController,
                              prefixIcon: Icons.email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.email,
                            ),
                            const SizedBox(height: 20),
                            PrimaryGradientButton(text: 'Send Reset Link', onPressed: _send, isLoading: _loading),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => Navigator.pushReplacementNamed(context, AppConstants.loginRoute),
                              child: const Text('Back to Login'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
