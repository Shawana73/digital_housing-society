import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';
import '../viewmodels/admin_view_models.dart';
import '../widgets/admin_shell.dart';
import '../widgets/app_snack.dart';
import '../widgets/premium_widgets.dart';

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

  void _refresh() { if (mounted) setState(() {}); }

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
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () { setState(() { _viewModel.name = name.text; _viewModel.email = email.text; _viewModel.phone = phone.text; }); Navigator.pop(context); showAdminSnack(context, 'Profile updated'); }, child: const Text('Save Changes'))),
        ]),
      ),
    );
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminColors.radius)),
        title: const Text('Change password'),
        content: const Text('Password change option clicked. Connect backend later for real password update.'),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminColors.radius)),
        title: const Text('Logout?'),
        content: const Text('This is a dummy logout action.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () { Navigator.pop(context); showAdminSnack(context, 'Logout clicked'); }, child: const Text('Logout')),
        ],
      ),
    );
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
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: AdminColors.primaryGradient, boxShadow: [BoxShadow(color: AdminColors.primary.withOpacity(0.25), blurRadius: 22, offset: const Offset(0, 10))]),
                  child: const CircleAvatar(radius: 48, backgroundColor: AdminColors.white, child: Icon(Icons.person_rounded, color: AdminColors.primary, size: 46)),
                ),
              ),
              const SizedBox(height: 14),
              Text(_viewModel.name, textAlign: TextAlign.center, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 25, letterSpacing: -0.7)),
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
          _SettingsTile(icon: Icons.settings_rounded, title: 'Settings', subtitle: 'Account, security and preferences', onTap: () => showAdminSnack(context, 'Settings clicked')),
          _SettingsTile(icon: Icons.notifications_rounded, title: 'Notification Preferences', subtitle: 'Manage alerts and reminders', onTap: () => showAdminSnack(context, 'Notification settings clicked')),
          _SettingsTile(icon: Icons.lock_rounded, title: 'Change Password', subtitle: 'Update admin password', onTap: _changePassword),
          _SettingsTile(icon: Icons.logout_rounded, title: 'Logout', subtitle: 'Sign out from admin panel', color: AdminColors.rejected, onTap: _logout),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.title, required this.subtitle, this.color = AdminColors.primary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        onTap: onTap,
        padding: const EdgeInsets.all(15),
        child: Row(children: [
          GradientIconBox(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w700, fontSize: 12)),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, color: AdminColors.greyText, size: 16),
        ]),
      ),
    );
  }
}
