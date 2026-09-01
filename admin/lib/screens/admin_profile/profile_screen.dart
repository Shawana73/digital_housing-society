import 'package:flutter/material.dart';
import '../../app_routes.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_shell.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/premium_widgets.dart';
import '../admin_settings/admin_settings_screen.dart';
import '../notification_preferences/notification_preferences_screen.dart';
import 'profile_viewmodel.dart';
import 'profile_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileViewModel _viewModel = ProfileViewModel();
  final TextEditingController _searchController = TextEditingController();

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
    _searchController.dispose();
    super.dispose();
  }

  void _editProfile() {
    final name = TextEditingController(text: _viewModel.name);
    final email = TextEditingController(text: _viewModel.email);
    final phone = TextEditingController(text: _viewModel.phone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AdminColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SectionHeader(title: 'Edit Profile', subtitle: 'Update local admin data'),
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_rounded))),
          const SizedBox(height: 12),
          TextField(controller: email, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_rounded))),
          const SizedBox(height: 12),
          TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_rounded))),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                final success = await _viewModel.updateProfile(
                  newName: name.text,
                  newEmail: email.text,
                  newPhone: phone.text,
                );

                if (!mounted) return;

                if (success) {
                  Navigator.pop(context);
                  showAdminSnack(context, 'Profile updated successfully');
                } else {
                  showAdminSnack(context, 'Failed to update profile');
                }
              },
              child: const Text('Save Changes'),
            ),
          ),
        ]),
      ),
    );
  }

  void _changePassword() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isChanging = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AdminColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminColors.radius)),
              title: const Text('Change Password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentPasswordController,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                          icon: Icon(obscureCurrent ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(Icons.lock_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                          icon: Icon(obscureNew ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        prefixIcon: const Icon(Icons.lock_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                          icon: Icon(obscureConfirm ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isChanging ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isChanging
                      ? null
                      : () async {
                    setDialogState(() => isChanging = true);

                    final error = await _viewModel.changePassword(
                      currentPassword: currentPasswordController.text.trim(),
                      newPassword: newPasswordController.text.trim(),
                      confirmPassword: confirmPasswordController.text.trim(),
                    );

                    if (!mounted) return;

                    if (error == null) {
                      Navigator.pop(dialogContext);
                      showAdminSnack(context, 'Password changed successfully');
                    } else {
                      setDialogState(() => isChanging = false);
                      showAdminSnack(context, error);
                    }
                  },
                  child: isChanging
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Change Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminColors.radius)),
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to sign out from the admin panel?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
        ],
      ),
    );

    if (shouldLogout != true) return;

    final error = await _viewModel.logout();

    if (!mounted) return;

    if (error == null) {
      Navigator.pushNamedAndRemoveUntil(context, AdminRoutes.login, (route) => false);
    } else {
      showAdminSnack(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Profile',
      selectedIndex: 4,
      searchController: _searchController,
      searchHint: 'Search profile settings...',
      onSearchClear: _searchController.clear,
      onFabTap: _editProfile,
      fabLabel: 'Edit',
      fabIcon: Icons.edit_rounded,
      isLoading: _viewModel.isLoading,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        children: [
          PremiumCard(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Hero(
                tag: 'admin-profile-hero',
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AdminColors.primaryGradient,
                    boxShadow: [BoxShadow(color: AdminColors.primary.withOpacity(0.25), blurRadius: 22, offset: const Offset(0, 10))],
                  ),
                  child: const CircleAvatar(radius: 48, backgroundColor: AdminColors.white, child: Icon(Icons.person_rounded, color: AdminColors.primary, size: 46)),
                ),
              ),
              const SizedBox(height: 14),
              Text(_viewModel.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 25, letterSpacing: -0.7)),
              const SizedBox(height: 8),
              StatusPill(label: _viewModel.role, color: AdminColors.primary, icon: Icons.admin_panel_settings_rounded),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: OutlinedButton.icon(onPressed: _changePassword, icon: const Icon(Icons.lock_rounded), label: const Text('Password'))),
                const SizedBox(width: 10),
                Expanded(child: FilledButton.icon(onPressed: _editProfile, icon: const Icon(Icons.edit_rounded), label: const Text('Edit Profile'))),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          PremiumCard(
            child: Column(children: [
              InfoRow(icon: Icons.email_rounded, label: 'Email', value: _viewModel.email),
              InfoRow(icon: Icons.phone_rounded, label: 'Phone', value: _viewModel.phone),
              const InfoRow(icon: Icons.location_city_rounded, label: 'Office', value: 'Digital Housing Society HQ'),
              const InfoRow(icon: Icons.verified_user_rounded, label: 'Access', value: 'Full Admin Permissions'),
            ]),
          ),
          const SizedBox(height: 16),
          ProfileSettingsTile(
            icon: Icons.settings_rounded,
            title: 'Settings',
            subtitle: 'Account, security and preferences',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSettingsScreen()));
            },
          ),
          ProfileSettingsTile(
            icon: Icons.notifications_rounded,
            title: 'Notification Preferences',
            subtitle: 'Manage alerts and reminders',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen()));
            },
          ),
          ProfileSettingsTile(icon: Icons.lock_rounded, title: 'Change Password', subtitle: 'Update admin password', onTap: _changePassword),
          ProfileSettingsTile(icon: Icons.logout_rounded, title: 'Logout', subtitle: 'Sign out from admin panel', color: AdminColors.rejected, onTap: _logout),
        ],
      ),
    );
  }
}