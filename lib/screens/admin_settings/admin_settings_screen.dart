import 'package:flutter/material.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_shell.dart';
import '../../widgets/premium_widgets.dart';
import 'settings_viewmodel.dart';
import 'settings_widgets.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final SettingsViewModel _viewModel = SettingsViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_refresh);
    _viewModel.load();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_refresh);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Settings',
      selectedIndex: 4,
      body: _viewModel.isLoading
          ? const Center(child: CircularProgressIndicator(color: AdminColors.primary))
          : ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        children: [
          PremiumCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Account Settings',
                    style: TextStyle(color: AdminColors.darkText, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text('Manage your admin panel preferences.',
                    style: TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600)),
                const SizedBox(height: 18),
                SettingSwitchTile(
                  icon: Icons.login_rounded,
                  title: 'Remember Session',
                  subtitle: 'Keep your admin session active when possible',
                  value: _viewModel.rememberSession,
                  onChanged: _viewModel.setRememberSession,
                ),
                const Divider(height: 24),
                SettingSwitchTile(
                  icon: Icons.verified_user_rounded,
                  title: 'Confirm Sensitive Actions',
                  subtitle: 'Ask for confirmation before important actions',
                  value: _viewModel.confirmSensitiveActions,
                  onChanged: _viewModel.setConfirmSensitiveActions,
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
                const Text('Security',
                    style: TextStyle(color: AdminColors.darkText, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                SettingActionTile(
                  icon: Icons.lock_rounded,
                  title: 'Change Password',
                  subtitle: 'Update your admin account password',
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}