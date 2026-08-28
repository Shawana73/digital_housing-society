import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_shell.dart';
import '../widgets/premium_widgets.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = true;
  bool rememberSession = true;
  bool confirmSensitiveActions = true;
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  Future<void> _loadSettings() async {
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
        final settings =
        data['settings'] as Map<String, dynamic>?;

        if (settings != null) {
          rememberSession =
              settings['rememberSession'] ?? true;

          confirmSensitiveActions =
              settings['confirmSensitiveActions'] ?? true;
        }
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
  Future<void> _saveSettings() async {
    try {
      final user = _auth.currentUser;

      if (user == null) return;

      await _firestore
          .collection('admins')
          .doc(user.uid)
          .set({
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
  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Settings',
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
                  'Account Settings',
                  style: TextStyle(
                    color: AdminColors.darkText,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Manage your admin panel preferences.',
                  style: TextStyle(
                    color: AdminColors.greyText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),

                _SettingSwitchTile(
                  icon: Icons.login_rounded,
                  title: 'Remember Session',
                  subtitle:
                  'Keep your admin session active when possible',
                  value: rememberSession,
                  onChanged: (value) async {
                    setState(() {
                      rememberSession = value;
                    });

                    await _saveSettings();
                  },
                ),

                const Divider(height: 24),

                _SettingSwitchTile(
                  icon: Icons.verified_user_rounded,
                  title: 'Confirm Sensitive Actions',
                  subtitle:
                  'Ask for confirmation before important actions',
                  value: confirmSensitiveActions,
                  onChanged: (value) async {
                    setState(() {
                      confirmSensitiveActions = value;
                    });

                    await _saveSettings();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          PremiumCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Security',
                  style: TextStyle(
                    color: AdminColors.darkText,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),

                _SettingActionTile(
                  icon: Icons.lock_rounded,
                  title: 'Change Password',
                  subtitle: 'Update your admin account password',
                  onTap: () {
                    Navigator.pop(context);
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

class _SettingSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            onChanged: onChanged,
            activeColor: AdminColors.primary,
          ),
        ],
      ),
    );
  }
}

class _SettingActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
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

            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AdminColors.greyText,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}