import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_routes.dart';
import '../../theme/admin_theme.dart';

class AdminSignupScreen extends StatefulWidget {
  const AdminSignupScreen({super.key});

  @override
  State<AdminSignupScreen> createState() => _AdminSignupScreenState();
}

class _AdminSignupScreenState extends State<AdminSignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSigningUp = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ================================================================
  // SIGN UP LOGIC
  // ================================================================

  Future<void> _handleSignup() async {
    if (_isSigningUp) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showError('Please fill all fields.');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }

    if (password != confirmPassword) {
      _showError('Passwords do not match.');
      return;
    }

    setState(() => _isSigningUp = true);

    try {
      // Check invite whitelist BEFORE creating the auth account.
      final inviteDoc = await FirebaseFirestore.instance
          .collection('invited_admins')
          .doc(email)
          .get();

      if (!inviteDoc.exists) {
        setState(() => _isSigningUp = false);

        _showError(
          'You are not invited to join as admin. '
              'Please contact your super admin.',
        );

        return;
      }

      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;

      if (uid == null) {
        setState(() => _isSigningUp = false);

        _showError('Something went wrong. Please try again.');

        return;
      }

      await FirebaseFirestore.instance.collection('admins').doc(uid).set({
        'name': name,
        'email': email,
        'phone': '',
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Remove the invite so it can't be reused.
      await FirebaseFirestore.instance
          .collection('invited_admins')
          .doc(email)
          .delete();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        AdminRoutes.dashboard,
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _isSigningUp = false);

      if (e.code == 'email-already-in-use') {
        _showError(
          'An account with this email already exists. Please login instead.',
        );
      } else if (e.code == 'invalid-email') {
        _showError('Please enter a valid email address.');
      } else if (e.code == 'weak-password') {
        _showError('Password is too weak.');
      } else {
        _showError('Signup failed. Please try again.');
      }
    } catch (e) {
      setState(() => _isSigningUp = false);

      _showError('Something went wrong. Please try again.');
    }
  }

  // ================================================================
  // ERROR SNACKBAR
  // ================================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ================================================================
  // RESPONSIVE UI
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final bool isMobile = screenWidth < 600;
    final bool isTablet = screenWidth >= 600 && screenWidth < 1000;

    final double horizontalPadding = isMobile
        ? 18
        : isTablet
        ? 40
        : 60;

    return Scaffold(
      body: Stack(
        children: [
          // ==========================================================
          // FULL SCREEN BACKGROUND IMAGE
          // ==========================================================

          Positioned.fill(
            child: Image.asset(
              'assets/images/admin_villa.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),

          // ==========================================================
          // IMAGE OVERLAY
          // ==========================================================

          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AdminColors.darkText.withOpacity(0.35),
                    AdminColors.primary.withOpacity(0.28),
                    AdminColors.darkText.withOpacity(0.72),
                  ],
                  stops: const [
                    0.0,
                    0.48,
                    1.0,
                  ],
                ),
              ),
            ),
          ),

          // ==========================================================
          // SOFT WHITE GLOW
          // ==========================================================

          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),

          Positioned(
            bottom: -120,
            left: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AdminColors.primary.withOpacity(0.12),
              ),
            ),
          ),

          // ==========================================================
          // MAIN CONTENT
          // ==========================================================

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: isMobile ? 22 : 40,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1080,
                  ),
                  child: isMobile
                      ? _buildMobileLayout()
                      : _buildDesktopLayout(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // MOBILE LAYOUT
  // ================================================================

  Widget _buildMobileLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBrandHeader(
          compact: true,
        ),
        const SizedBox(height: 22),
        _buildSignupCard(
          compact: true,
        ),
        const SizedBox(height: 18),
        _buildFooter(),
      ],
    );
  }

  // ================================================================
  // DESKTOP / TABLET LAYOUT
  // ================================================================

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ------------------------------------------------------------
        // LEFT BRANDING SECTION
        // ------------------------------------------------------------

        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.only(
              right: 55,
            ),
            child: _buildBrandingSection(),
          ),
        ),

        // ------------------------------------------------------------
        // RIGHT SIGNUP CARD
        // ------------------------------------------------------------

        Expanded(
          flex: 5,
          child: _buildSignupCard(
            compact: false,
          ),
        ),
      ],
    );
  }

  // ================================================================
  // DESKTOP BRANDING
  // ================================================================

  Widget _buildBrandingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: _buildLogo(
            size: 92,
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'DIGITAL',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 5,
          ),
        ),

        const SizedBox(height: 2),

        const Text(
          'HOUSING SOCIETY',
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),

        const SizedBox(height: 14),

        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        const SizedBox(height: 18),

        Text(
          'A smarter way to manage housing society operations, '
              'applications and administration.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.86),
            fontSize: 15,
            height: 1.6,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 30),

        _buildFeature(
          icon: Icons.security_rounded,
          title: 'Secure Administration',
          subtitle: 'Controlled access for authorized administrators.',
        ),

        const SizedBox(height: 15),

        _buildFeature(
          icon: Icons.apartment_rounded,
          title: 'Centralized Management',
          subtitle: 'Manage your housing society from one platform.',
        ),

        const SizedBox(height: 15),

        _buildFeature(
          icon: Icons.verified_rounded,
          title: 'Invitation Based Access',
          subtitle: 'Only approved admins can create an account.',
        ),
      ],
    );
  }

  // ================================================================
  // MOBILE / COMPACT BRAND HEADER
  // ================================================================

  Widget _buildBrandHeader({
    required bool compact,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLogo(
          size: compact ? 76 : 92,
        ),

        const SizedBox(height: 13),

        const Text(
          'DIGITAL HOUSING SOCIETY',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          'ADMIN PORTAL',
          style: TextStyle(
            color: Colors.white.withOpacity(0.78),
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  // ================================================================
  // LOGO
  // ================================================================

  Widget _buildLogo({
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.85),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/logo/dhs_logo.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // ================================================================
  // SIGNUP CARD
  // ================================================================

  Widget _buildSignupCard({
    required bool compact,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        maxWidth: 500,
      ),
      padding: EdgeInsets.all(
        compact ? 22 : 30,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(
          compact ? 26 : 30,
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 45,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ----------------------------------------------------------
          // CARD HEADER
          // ----------------------------------------------------------

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AdminColors.primary,
                      AdminColors.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: AdminColors.primary.withOpacity(0.22),
                      blurRadius: 15,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        color: AdminColors.darkText,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Create your authorized admin profile',
                      style: TextStyle(
                        color: AdminColors.greyText.withOpacity(0.95),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ----------------------------------------------------------
          // INVITATION INFO
          // ----------------------------------------------------------

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: AdminColors.primary.withOpacity(0.055),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AdminColors.primary.withOpacity(0.12),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AdminColors.primary.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: AdminColors.primary,
                    size: 16,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'Admin access is invitation-only. '
                        'Use the email address provided by your Super Admin.',
                    style: TextStyle(
                      color: AdminColors.darkText.withOpacity(0.70),
                      fontSize: 11,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ----------------------------------------------------------
          // FULL NAME
          // ----------------------------------------------------------

          _buildSignupField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'Enter your full name',
            icon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: 13),

          // ----------------------------------------------------------
          // EMAIL
          // ----------------------------------------------------------

          _buildSignupField(
            controller: _emailController,
            label: 'Invited Email',
            hint: 'Enter your invited email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: 13),

          // ----------------------------------------------------------
          // PASSWORD
          // ----------------------------------------------------------

          _buildSignupField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Create a secure password',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            suffixIcon: IconButton(
              splashRadius: 20,
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AdminColors.greyText,
                size: 20,
              ),
            ),
          ),

          const SizedBox(height: 13),

          // ----------------------------------------------------------
          // CONFIRM PASSWORD
          // ----------------------------------------------------------

          _buildSignupField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            icon: Icons.lock_rounded,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            suffixIcon: IconButton(
              splashRadius: 20,
              onPressed: () {
                setState(() {
                  _obscureConfirm = !_obscureConfirm;
                });
              },
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AdminColors.greyText,
                size: 20,
              ),
            ),
            onSubmitted: (_) {
              if (!_isSigningUp) {
                _handleSignup();
              }
            },
          ),

          const SizedBox(height: 22),

          // ----------------------------------------------------------
          // CREATE ACCOUNT BUTTON
          // ----------------------------------------------------------

          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: _isSigningUp ? null : _handleSignup,
              style: FilledButton.styleFrom(
                backgroundColor: AdminColors.primary,
                disabledBackgroundColor:
                AdminColors.primary.withOpacity(0.55),
                elevation: 5,
                shadowColor: AdminColors.primary.withOpacity(0.28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _isSigningUp
                    ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
                    : Row(
                  key: const ValueKey('button'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.person_add_rounded,
                      size: 19,
                    ),
                    SizedBox(width: 9),
                    Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),

          // ----------------------------------------------------------
          // LOGIN
          // ----------------------------------------------------------

          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(
                  context,
                  AdminRoutes.login,
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: AdminColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
              ),
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    color: AdminColors.greyText,
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    TextSpan(
                      text: 'Already have an account?  ',
                    ),
                    TextSpan(
                      text: 'Login',
                      style: TextStyle(
                        color: AdminColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // TEXT FIELD
  // ================================================================

  Widget _buildSignupField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    Widget? suffixIcon,
    void Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onSubmitted: onSubmitted,
      cursorColor: AdminColors.primary,
      style: const TextStyle(
        color: AdminColors.darkText,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: AdminColors.primary,
          size: 20,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AdminColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),

        // ------------------------------------------------------------
        // LABEL
        // ------------------------------------------------------------

        labelStyle: const TextStyle(
          color: AdminColors.greyText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),

        floatingLabelStyle: const TextStyle(
          color: AdminColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),

        // ------------------------------------------------------------
        // HINT
        // ------------------------------------------------------------

        hintStyle: TextStyle(
          color: AdminColors.greyText.withOpacity(0.52),
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        ),

        // ------------------------------------------------------------
        // NORMAL BORDER
        // ------------------------------------------------------------

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: AdminColors.border.withOpacity(0.8),
          ),
        ),

        // ------------------------------------------------------------
        // ENABLED BORDER
        // ------------------------------------------------------------

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: AdminColors.border.withOpacity(0.8),
          ),
        ),

        // ------------------------------------------------------------
        // FOCUSED BORDER
        // ------------------------------------------------------------

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AdminColors.primary,
            width: 1.5,
          ),
        ),

        // ------------------------------------------------------------
        // ERROR BORDER
        // ------------------------------------------------------------

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Colors.redAccent,
          ),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ================================================================
  // DESKTOP FEATURES
  // ================================================================

  Widget _buildFeature({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.13),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.68),
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================================================================
  // BACK BUTTON
  // ================================================================


  // ================================================================
  // FOOTER
  // ================================================================

  Widget _buildFooter() {
    return Text(
      'Secure administration • Digital Housing Society',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white.withOpacity(0.70),
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}