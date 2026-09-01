import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../widgets/responsive_shell.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirestoreService _service = FirestoreService();
  bool _notifications = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final doc = await _service.getApplicant(uid);
      final data = doc.data() as Map<String, dynamic>? ?? {};
      if (mounted) {
        setState(() {
          _notifications = data['notificationsEnabled'] != false;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _notifications = value);
    try {
      await _service.updateApplicant(uid, {'notificationsEnabled': value});
    } catch (_) {
      if (!mounted) return;
      setState(() => _notifications = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update notification preference.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DhsResponsiveShell(
      currentRoute: AppConstants.settingsRoute,
      mobileTitle: 'Settings',
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPurple),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Settings & Preferences',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Manage account security, notifications and legal preferences.',
                  style: TextStyle(color: AppColors.secondaryText),
                ),
                const SizedBox(height: 22),
                _SettingsCard(
                  icon: Icons.lock_outline_rounded,
                  title: 'Change Password',
                  subtitle: 'Update your Firebase account password securely.',
                  onTap: () => _sendReset(context),
                ),
                const SizedBox(height: 12),
                _SettingsCard(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  subtitle: 'Receive application, payment and balloting updates.',
                  trailing: Switch(
                    value: _notifications,
                    onChanged: _toggleNotifications,
                    activeThumbColor: AppColors.deepPurple,
                  ),
                ),
                const SizedBox(height: 12),
                _SettingsCard(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'Read how DHS handles applicant information.',
                  onTap: () =>
                      Navigator.pushNamed(context, AppConstants.privacyRoute),
                ),
                const SizedBox(height: 12),
                _SettingsCard(
                  icon: Icons.gavel_outlined,
                  title: 'Terms & Conditions',
                  subtitle: 'Review the DHS applicant terms of use.',
                  onTap: () =>
                      Navigator.pushNamed(context, AppConstants.termsRoute),
                ),
                const SizedBox(height: 12),
                _SettingsCard(
                  icon: Icons.support_agent_rounded,
                  title: 'Contact DHS',
                  subtitle: 'Open the support and contact center.',
                  onTap: () =>
                      Navigator.pushNamed(context, AppConstants.contactRoute),
                ),
              ],
            ),
    );
  }

  Future<void> _sendReset(BuildContext context) async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null || email.isEmpty) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent.'),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email could not be sent.'),
        ),
      );
    }
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE8E6F1)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B2EEA).withValues(alpha: .06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0ECFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.deepPurple),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.deepPurple,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
