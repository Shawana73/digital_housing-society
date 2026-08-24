import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';
import '../widgets/premium_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_routes.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─── FIRESTORE / AUTH CODE — UNCHANGED ────────────────────────────────────
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter email and password'),
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        AdminRoutes.dashboard,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';

      if (e.code == 'user-not-found') {
        message = 'No admin account found with this email.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Incorrect email or password.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    }
  }
  // ──────────────────────────────────────────────────────────────────────────

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
              // ── Purple hero section ──────────────────────────────────
              _HeroSection(),

              // ── White form section ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Heading
                    const Text(
                      'Login Credentials',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AdminColors.darkText,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enter your credentials to continue',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AdminColors.greyText,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Email label + field
                    const _FieldLabel(text: 'Email or Username'),
                    const SizedBox(height: 8),
                    _InputField(
                      controller: _emailController,
                      hintText: 'Enter admin email or username',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.person_outline_rounded,
                    ),

                    const SizedBox(height: 18),

                    // Password label + field
                    const _FieldLabel(text: 'Password'),
                    const SizedBox(height: 8),
                    _PasswordField(
                      controller: _passwordController,
                      obscure: _obscurePassword,
                      onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),

                    const SizedBox(height: 12),

                    // Remember me + Forgot password
                    Row(children: [
                      GestureDetector(
                        onTap: () => setState(() => _rememberMe = !_rememberMe),
                        child: Row(children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 22, width: 22,
                            decoration: BoxDecoration(
                              color: _rememberMe
                                  ? AdminColors.primary
                                  : AdminColors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _rememberMe
                                    ? AdminColors.primary
                                    : AdminColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: _rememberMe
                                ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 14)
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Remember me',
                            style: TextStyle(
                              color: AdminColors.greyText,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ]),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Password reset will be connected later.'),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AdminColors.primary,
                          padding: EdgeInsets.zero,
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        child: const Text('Forgot Password?'),
                      ),
                    ]),

                    const SizedBox(height: 22),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AdminColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AdminColors.primary.withOpacity(0.28),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shield_rounded,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Login to Admin Panel',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Secure admin access card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AdminColors.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(children: [
                        Container(
                          height: 52, width: 52,
                          decoration: BoxDecoration(
                            color: AdminColors.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_user_rounded,
                              color: AdminColors.primary, size: 26),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Secure Admin Access',
                                style: TextStyle(
                                  color: AdminColors.darkText,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'All admin actions are monitored and logged for security and transparency.',
                                style: TextStyle(
                                  color: AdminColors.greyText,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 28),

                    // Powered by footer
                    Center(
                      child: RichText(
                        text: TextSpan(children: [
                          const TextSpan(
                            text: 'Powered by ',
                            style: TextStyle(
                              color: AdminColors.greyText,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const TextSpan(
                            text: 'Digital Housing Society',
                            style: TextStyle(
                              color: AdminColors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Hero section — purple gradient + building image + icon + title
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight * 0.38,
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(0)),
        image: DecorationImage(
          image: AssetImage('assets/images/modern_apartment.png'),
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
        ),
      ),
      child: Stack(children: [
        // Purple overlay — light enough for background image to show
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF4A28D4).withOpacity(0.72),
                const Color(0xFF6A3CEF).withOpacity(0.65),
                const Color(0xFF7B4DFF).withOpacity(0.55),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        // Second tint layer — reduced opacity so image is visible
        Container(
          color: const Color(0xFF5A30E8).withOpacity(0.35),
        ),

        // Content
        SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App icon
                Container(
                  height: 80, width: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.30), width: 1.5),
                  ),
                  child: const Icon(
                    Icons.home_work_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Admin Login',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.6,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Welcome back! Please login to\naccess the admin panel',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AdminColors.darkText,
        fontWeight: FontWeight.w800,
        fontSize: 13.5,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final IconData prefixIcon;

  const _InputField({
    required this.controller,
    required this.hintText,
    required this.keyboardType,
    required this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AdminColors.primary.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: AdminColors.darkText,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: AdminColors.greyText,
            fontWeight: FontWeight.w500,
            fontSize: 13.5,
          ),
          prefixIcon: Icon(prefixIcon,
              color: AdminColors.primary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AdminColors.primary.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(
          color: AdminColors.darkText,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Enter your password',
          hintStyle: const TextStyle(
            color: AdminColors.greyText,
            fontWeight: FontWeight.w500,
            fontSize: 13.5,
          ),
          prefixIcon: const Icon(Icons.lock_outline_rounded,
              color: AdminColors.primary, size: 20),
          suffixIcon: IconButton(
            onPressed: onToggle,
            icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AdminColors.greyText,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

