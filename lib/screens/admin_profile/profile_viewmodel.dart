import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
}