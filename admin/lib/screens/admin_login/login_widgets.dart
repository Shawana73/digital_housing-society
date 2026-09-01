import 'package:flutter/material.dart';
import '../../theme/admin_theme.dart';

class LoginHeroSection extends StatelessWidget {
  const LoginHeroSection({super.key});

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
        Container(color: const Color(0xFF5A30E8).withOpacity(0.35)),
        SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withOpacity(0.30), width: 1.5),
                  ),
                  child: const Icon(Icons.home_work_rounded, color: Colors.white, size: 42),
                ),
                const SizedBox(height: 18),
                const Text('Admin Login',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -.6)),
                const SizedBox(height: 8),
                const Text('Welcome back! Please login to\naccess the admin panel',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600, height: 1.45)),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class LoginFieldLabel extends StatelessWidget {
  final String text;
  const LoginFieldLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w800, fontSize: 13.5));
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
      decoration: BoxDecoration(
        color: AdminColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border, width: 1.2),
        boxShadow: [BoxShadow(color: AdminColors.primary.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w700, fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w500, fontSize: 13.5),
          prefixIcon: Icon(prefixIcon, color: AdminColors.primary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      decoration: BoxDecoration(
        color: AdminColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border, width: 1.2),
        boxShadow: [BoxShadow(color: AdminColors.primary.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w700, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Enter your password',
          hintStyle: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w500, fontSize: 13.5),
          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AdminColors.primary, size: 20),
          suffixIcon: IconButton(
            onPressed: onToggle,
            icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AdminColors.greyText, size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}