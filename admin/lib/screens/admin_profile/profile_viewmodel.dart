import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../viewmodels/admin_view_models.dart'; // for BaseAdminViewModel

class ProfileViewModel extends BaseAdminViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String name = '';
  String email = '';
  String phone = '';
  String role = '';

  @override
  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return;
      }

      final doc = await _firestore.collection('admins').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        name = data['name'] ?? '';
        email = data['email'] ?? '';
        phone = data['phone'] ?? '';
        role = data['role'] ?? '';
      }
    } catch (e) {
      // Error loading admin profile
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String newName,
    required String newEmail,
    required String newPhone,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      await _firestore.collection('admins').doc(user.uid).update({
        'name': newName.trim(),
        'email': newEmail.trim(),
        'phone': newPhone.trim(),
      });

      name = newName.trim();
      email = newEmail.trim();
      phone = newPhone.trim();

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Returns null on success, or an error message string on failure.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      return 'Please fill all password fields';
    }
    if (newPassword.length < 6) {
      return 'New password must be at least 6 characters';
    }
    if (newPassword != confirmPassword) {
      return 'New passwords do not match';
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw FirebaseAuthException(code: 'no-user', message: 'No admin is currently logged in.');
      }

      final credential = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Current password is incorrect.';
      } else if (e.code == 'weak-password') {
        return 'New password is too weak.';
      } else if (e.code == 'requires-recent-login') {
        return 'Please login again and try changing the password.';
      }
      return 'Unable to change password';
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  /// Returns null on success, or an error message string on failure.
  Future<String?> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      return null;
    } on FirebaseAuthException catch (e) {
      return 'Logout failed: ${e.message ?? 'Please try again'}';
    }
  }
  /// Returns null on success, or an error message string on failure.
  Future<String?> inviteAdmin(String inviteEmail) async {
    final emailToInvite = inviteEmail.trim().toLowerCase();

    if (emailToInvite.isEmpty) {
      return 'Please enter an email address.';
    }
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(emailToInvite)) {
      return 'Please enter a valid email address.';
    }

    try {
      final existingInvite = await _firestore.collection('invited_admins').doc(emailToInvite).get();
      if (existingInvite.exists) {
        return 'This email has already been invited.';
      }

      await _firestore.collection('invited_admins').doc(emailToInvite).set({
        'email': emailToInvite,
        'invitedBy': FirebaseAuth.instance.currentUser?.uid,
        'invitedAt': FieldValue.serverTimestamp(),
      });

      final emailSent = await _sendInviteEmail(emailToInvite);
      if (!emailSent) {
        return 'Invite saved, but the email could not be sent. Please inform them manually.';
      }

      return null;
    } catch (e) {
      return 'Could not send invitation. Please try again.';
    }
  }

  Future<bool> _sendInviteEmail(String toEmail) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': 'service_bj4eqpa',
          'template_id': 'template_27g6mfa',
          'user_id': 'l1_JctY7GkYlQh0kP',
          'template_params': {
            'to_email': toEmail,
          },
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}