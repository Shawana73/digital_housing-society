import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginViewModel extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;
  bool rememberMe = false;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void toggleRememberMe() {
    rememberMe = !rememberMe;
    notifyListeners();
  }

  Future<String?> resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      return 'Please enter your email!';
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );
      return null;
    } catch (e) {
      return 'Password reset failed: $e';
    }
  }

  /// Returns null on success, or an error message string on failure.
  Future<String?> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      return 'Please enter email and password';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No admin account found with this email.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Incorrect email or password.';
      } else if (e.code == 'invalid-email') {
        return 'Please enter a valid email address.';
      }
      return 'Login failed';
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}