import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PreferencesViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = true;
  bool notificationsEnabled = true;
  bool applicantUpdates = true;
  bool paymentUpdates = true;
  bool ballotingAlerts = true;
  bool systemAlerts = true;

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
        final preferences = data['notificationPreferences'] as Map<String, dynamic>?;
        if (preferences != null) {
          notificationsEnabled = preferences['notificationsEnabled'] ?? true;
          applicantUpdates = preferences['applicantUpdates'] ?? true;
          paymentUpdates = preferences['paymentUpdates'] ?? true;
          ballotingAlerts = preferences['ballotingAlerts'] ?? true;
          systemAlerts = preferences['systemAlerts'] ?? true;
        }
      }
    } catch (e) {
      debugPrint('Error loading notification preferences: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('admins').doc(user.uid).set({
        'notificationPreferences': {
          'notificationsEnabled': notificationsEnabled,
          'applicantUpdates': applicantUpdates,
          'paymentUpdates': paymentUpdates,
          'ballotingAlerts': ballotingAlerts,
          'systemAlerts': systemAlerts,
        },
      }, SetOptions(merge: true));

      debugPrint('Notification preferences saved successfully');
    } catch (e) {
      debugPrint('Error saving notification preferences: $e');
    }
  }

  Future<void> setNotificationsEnabled(bool value) async {
    notificationsEnabled = value;
    notifyListeners();
    await _savePreferences();
  }

  Future<void> setApplicantUpdates(bool value) async {
    applicantUpdates = value;
    notifyListeners();
    await _savePreferences();
  }

  Future<void> setPaymentUpdates(bool value) async {
    paymentUpdates = value;
    notifyListeners();
    await _savePreferences();
  }

  Future<void> setBallotingAlerts(bool value) async {
    ballotingAlerts = value;
    notifyListeners();
    await _savePreferences();
  }

  Future<void> setSystemAlerts(bool value) async {
    systemAlerts = value;
    notifyListeners();
    await _savePreferences();
  }
}