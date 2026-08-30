import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = true;
  bool rememberSession = true;
  bool confirmSensitiveActions = true;

  Future<void> load() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        isLoading = false;
        notifyListeners();
        return;
      }

      final doc = await _firestore.collection('admins').doc(user.uid).get();
      final data = doc.data();

      if (data != null) {
        final settings = data['settings'] as Map<String, dynamic>?;
        if (settings != null) {
          rememberSession = settings['rememberSession'] ?? true;
          confirmSensitiveActions = settings['confirmSensitiveActions'] ?? true;
        }
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('admins').doc(user.uid).set({
        'settings': {
          'rememberSession': rememberSession,
          'confirmSensitiveActions': confirmSensitiveActions,
        },
      }, SetOptions(merge: true));

      debugPrint('Settings saved successfully');
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  Future<void> setRememberSession(bool value) async {
    rememberSession = value;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setConfirmSensitiveActions(bool value) async {
    confirmSensitiveActions = value;
    notifyListeners();
    await _saveSettings();
  }
}