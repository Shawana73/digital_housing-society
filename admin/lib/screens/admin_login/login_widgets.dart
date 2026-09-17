import 'package:flutter/material.dart';
import '../../theme/admin_theme.dart';

class LoginHeroSection extends StatelessWidget {
  const LoginHeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 330,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/admin_realestate.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),

          // Purple overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF3E1FAF).withOpacity(0.20),
                  const Color(0xFF6A3CEF).withOpacity(0.18),
                  const Color(0xFF7B4DFF).withOpacity(0.15),
                ],
              ),
            ),
          ),

          // Extra soft overlay
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.2,
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Hero content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),

                  // Clean logo container
                  Container(
                    height: 88,
                    width: 88,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.16),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/logo/dhs_icon.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),

                  const SizedBox(height: 22),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: const Text(
                      'DIGITAL HOUSING SOCIETY',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'ADMIN PORTAL',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginFieldLabel extends StatelessWidget {
  final String text;

  const LoginFieldLabel({
    super.key,
    required this.text,
  });

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

class LoginInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final IconData prefixIcon;

  const LoginInputField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.keyboardType,
    required this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AdminColors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AdminColors.border,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AdminColors.primary.withOpacity(0.055),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.next,
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
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 5, right: 2),
            child: Icon(
              prefixIcon,
              color: AdminColors.primary,
              size: 21,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
        ),
      ),
    );
  }
}

class LoginPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  const LoginPasswordField({
    super.key,
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AdminColors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AdminColors.border,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AdminColors.primary.withOpacity(0.055),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        textInputAction: TextInputAction.done,
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
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 5, right: 2),
            child: Icon(
              Icons.lock_outline_rounded,
              color: AdminColors.primary,
              size: 21,
            ),
          ),
          suffixIcon: IconButton(
            onPressed: onToggle,
            splashRadius: 22,
            icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AdminColors.greyText,
              size: 21,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
        ),
      ),
    );
  }
}