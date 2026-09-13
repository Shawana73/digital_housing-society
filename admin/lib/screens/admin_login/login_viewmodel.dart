import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      return 'Could not send reset email. Please check the address and try again.';
    }
  }

  /// Returns null on success, or an error message string on failure.
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
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        return 'Something went wrong. Please try again.';
      }

      final adminDoc = await FirebaseFirestore.instance.collection('admins').doc(uid).get();
      if (!adminDoc.exists) {
        await FirebaseAuth.instance.signOut();
        return 'You are not authorized to access the admin panel.';
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', rememberMe);

      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
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