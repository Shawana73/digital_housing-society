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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _authService.login(_emailController.text, _passwordController.text);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppConstants.dashboardRoute, (_) => false);
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? e.code);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: BrandedImageBackground(
          imagePath: AppAssets.authBackground,
          overlayOpacity: .62,
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
                          border: Border.all(color: AppColors.white.withValues(alpha: .75)),
                          boxShadow: [
                            BoxShadow(color: AppColors.darkNavy.withValues(alpha: .16), blurRadius: 28, offset: const Offset(0, 18)),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Hero(
                                  tag: 'app-logo',
                                  child: Image.asset(AppAssets.logo, width: 145, fit: BoxFit.contain),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text('Welcome Back', style: AppTextStyles.headingLarge),
                              const SizedBox(height: 6),
                              Text('Login to manage your housing society application.', style: AppTextStyles.bodyMedium),
                              const SizedBox(height: 26),
                              AppTextField(
                                label: 'Email',
                                hint: 'you@example.com',
                                controller: _emailController,
                                prefixIcon: Icons.email_rounded,
                                keyboardType: TextInputType.emailAddress,
                                validator: Validators.email,
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                label: 'Password',
                                hint: 'Enter your password',
                                controller: _passwordController,
                                prefixIcon: Icons.lock_rounded,
                                obscureText: _obscure,
                                validator: (v) => Validators.required(v, 'Password'),
                                suffix: IconButton(
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                  icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => Navigator.pushNamed(context, AppConstants.forgotPasswordRoute),
                                  child: const Text('Forgot Password?'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              PrimaryGradientButton(text: 'Login', onPressed: _login, isLoading: _loading),
                              const SizedBox(height: 14),
                              Center(
                                child: TextButton(
                                  onPressed: () => Navigator.pushNamed(context, AppConstants.registerRoute),
                                  child: RichText(
                                    text: TextSpan(
                                      style: AppTextStyles.bodyMedium,
                                      children: [
                                        const TextSpan(text: "Don't have an account? "),
                                        TextSpan(text: 'Register', style: AppTextStyles.labelBold.copyWith(color: AppColors.primaryPurple)),
                                      ],
                                    ),
                                  ),
                                ),
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
      ),
    );
  }
}
