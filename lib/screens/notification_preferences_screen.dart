import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_shell.dart';
import '../widgets/premium_widgets.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = true;
  bool notificationsEnabled = true;
  bool applicantUpdates = true;
  bool paymentUpdates = true;
  bool ballotingAlerts = true;
  bool systemAlerts = true;
  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }
  Future<void> _loadPreferences() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final doc = await _firestore
          .collection('admins')
          .doc(user.uid)
          .get();

      final data = doc.data();

      if (data != null) {
        final preferences =
        data['notificationPreferences'] as Map<String, dynamic>?;

        if (preferences != null) {
          notificationsEnabled =
              preferences['notificationsEnabled'] ?? true;

          applicantUpdates =
              preferences['applicantUpdates'] ?? true;

          paymentUpdates =
              preferences['paymentUpdates'] ?? true;

          ballotingAlerts =
              preferences['ballotingAlerts'] ?? true;

          systemAlerts =
              preferences['systemAlerts'] ?? true;
        }
      }
    } catch (e) {
      debugPrint('Error loading notification preferences: $e');
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
  Future<void> _savePreferences() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return;
      }

      await _firestore
          .collection('admins')
          .doc(user.uid)
          .set({
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
  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Notification Preferences',
      selectedIndex: 4,
      body:isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: AdminColors.primary,
        ),
      )
      : ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        children: [
          PremiumCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notification Settings',
                  style: TextStyle(
                    color: AdminColors.darkText,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose which alerts you want to receive.',
                  style: TextStyle(
                    color: AdminColors.greyText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),

                _PreferenceTile(
                  icon: Icons.notifications_active_rounded,
                  title: 'Notifications',
                  subtitle: 'Enable or disable all admin notifications',
                  value: notificationsEnabled,
                  onChanged: (value) async {
                    setState(() {
                      notificationsEnabled = value;
                    });

                    await _savePreferences();
                  },
                ),

                const Divider(height: 24),

                _PreferenceTile(
                  icon: Icons.person_rounded,
                  title: 'Applicant Updates',
                  subtitle: 'Verification and applicant activity alerts',
                  value: applicantUpdates,
                  enabled: notificationsEnabled,
                  onChanged: (value) async {
                    setState(() {
                      applicantUpdates = value;
                    });

                    await _savePreferences();
                  },
                ),

                _PreferenceTile(
                  icon: Icons.payments_rounded,
                  title: 'Payment Updates',
                  subtitle: 'Payment verification and transaction alerts',
                  value: paymentUpdates,
                  enabled: notificationsEnabled,
                  onChanged: (value) async {
                    setState(() {
                      paymentUpdates = value;
                    });

                    await _savePreferences();
                  },
                ),

                _PreferenceTile(
                  icon: Icons.how_to_vote_rounded,
                  title: 'Balloting Alerts',
                  subtitle: 'Balloting process and result notifications',
                  value: ballotingAlerts,
                  enabled: notificationsEnabled,
                  onChanged: (value) async {
                    setState(() {
                      paymentUpdates = value;
                    });

                    await _savePreferences();
                  },
                ),

                _PreferenceTile(
                  icon: Icons.campaign_rounded,
                  title: 'System Alerts',
                  subtitle: 'Important system and admin notifications',
                  value: systemAlerts,
                  enabled: notificationsEnabled,
                  onChanged: (value) async {
                    setState(() {
                      systemAlerts = value;
                    });

                    await _savePreferences();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _PreferenceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            GradientIconBox(
              icon: icon,
              color: AdminColors.primary,
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AdminColors.darkText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AdminColors.greyText,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeColor: AdminColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}