import 'package:flutter/material.dart';
import '../../app_routes.dart';
import '../../theme/admin_theme.dart';
import 'login_viewmodel.dart';
import 'login_widgets.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final LoginViewModel _viewModel = LoginViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_refresh);
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final error = await _viewModel.login();

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    Navigator.pushReplacementNamed(context, AdminRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AdminColors.white,
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const LoginHeroSection(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Login Credentials',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AdminColors.darkText, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -.4)),
                    const SizedBox(height: 4),
                    const Text('Enter your credentials to continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AdminColors.greyText, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 24),
                    const LoginFieldLabel(text: 'Email or Username'),
                    const SizedBox(height: 8),
                    LoginInputField(
                      controller: _viewModel.emailController,
                      hintText: 'Enter admin email or username',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 18),
                    const LoginFieldLabel(text: 'Password'),
                    const SizedBox(height: 8),
                    LoginPasswordField(
                      controller: _viewModel.passwordController,
                      obscure: _viewModel.obscurePassword,
                      onToggle: _viewModel.togglePasswordVisibility,
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      GestureDetector(
                        onTap: _viewModel.toggleRememberMe,
                        child: Row(children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 22,
                            width: 22,
                            decoration: BoxDecoration(
                              color: _viewModel.rememberMe ? AdminColors.primary : AdminColors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _viewModel.rememberMe ? AdminColors.primary : AdminColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: _viewModel.rememberMe
                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(width: 8),
                          const Text('Remember me',
                              style: TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w700, fontSize: 13)),
                        ]),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password reset will be connected later.')),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AdminColors.primary,
                          padding: EdgeInsets.zero,
                          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        child: const Text('Forgot Password?'),
                      ),
                    ]),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AdminColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: AdminColors.primary.withOpacity(0.28), blurRadius: 18, offset: const Offset(0, 8))],
                        ),
                        child: ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 10),
                              Text('Login to Admin Panel',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AdminColors.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(18)),
                      child: Row(children: [
                        Container(
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(color: AdminColors.primary.withOpacity(0.12), shape: BoxShape.circle),
                          child: const Icon(Icons.verified_user_rounded, color: AdminColors.primary, size: 26),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Secure Admin Access',
                                  style: TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 14)),
                              SizedBox(height: 4),
                              Text('All admin actions are monitored and logged for security and transparency.',
                                  style: TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 12, height: 1.4)),
                            ],
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: RichText(
                        text: TextSpan(children: [
                          const TextSpan(text: 'Powered by ', style: TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 12)),
                          const TextSpan(text: 'Digital Housing Society', style: TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w900, fontSize: 12)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}