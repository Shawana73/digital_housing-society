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

  Future<void> _handleSignup() async {
    if (_isSigningUp) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
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
      final inviteDoc = await FirebaseFirestore.instance.collection('invited_admins').doc(email).get();
      if (!inviteDoc.exists) {
        setState(() => _isSigningUp = false);
        _showError('You are not invited to join as admin. Please contact your super admin.');
        return;
      }

      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
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
      await FirebaseFirestore.instance.collection('invited_admins').doc(email).delete();

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AdminRoutes.dashboard, (route) => false);
    } on FirebaseAuthException catch (e) {
      setState(() => _isSigningUp = false);
      if (e.code == 'email-already-in-use') {
        _showError('An account with this email already exists. Please login instead.');
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.white,
      appBar: AppBar(
        backgroundColor: AdminColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AdminColors.darkText),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admin Sign Up',
                style: TextStyle(color: AdminColors.darkText, fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text(
              'You must have been invited by a super admin to create an account.',
              style: TextStyle(color: AdminColors.greyText, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_rounded)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Invited Email', prefixIcon: Icon(Icons.email_rounded)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  icon: Icon(_obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                ),
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _isSigningUp ? null : _handleSignup,
                child: _isSigningUp
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : const Text('Create Account', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, AdminRoutes.login),
                child: const Text('Already have an account? Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}