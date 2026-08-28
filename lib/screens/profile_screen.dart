import 'package:flutter/material.dart';
import 'notification_preferences_screen.dart';
import 'admin_settings_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_routes.dart';
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
          SizedBox(width: double.infinity, child:
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

                  showAdminSnack(
                    context,
                    'Profile updated successfully',
                  );
                } else {
                  showAdminSnack(
                    context,
                    'Failed to update profile',
                  );
                }
              },
              child: const Text('Save Changes'),
            ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AdminColors.radius,
                ),
              ),
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
                          onPressed: () {
                            setDialogState(() {
                              obscureCurrent = !obscureCurrent;
                            });
                          },
                          icon: Icon(
                            obscureCurrent
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                          ),
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
                          onPressed: () {
                            setDialogState(() {
                              obscureNew = !obscureNew;
                            });
                          },
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                          ),
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
                          onPressed: () {
                            setDialogState(() {
                              obscureConfirm = !obscureConfirm;
                            });
                          },
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isChanging
                      ? null
                      : () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                FilledButton(
                  onPressed: isChanging
                      ? null
                      : () async {
                    final currentPassword =
                    currentPasswordController.text.trim();

                    final newPassword =
                    newPasswordController.text.trim();

                    final confirmPassword =
                    confirmPasswordController.text.trim();

                    if (currentPassword.isEmpty ||
                        newPassword.isEmpty ||
                        confirmPassword.isEmpty) {
                      showAdminSnack(
                        context,
                        'Please fill all password fields',
                      );
                      return;
                    }

                    if (newPassword.length < 6) {
                      showAdminSnack(
                        context,
                        'New password must be at least 6 characters',
                      );
                      return;
                    }

                    if (newPassword != confirmPassword) {
                      showAdminSnack(
                        context,
                        'New passwords do not match',
                      );
                      return;
                    }

                    setDialogState(() {
                      isChanging = true;
                    });

                    try {
                      final user =
                          FirebaseAuth.instance.currentUser;

                      if (user == null || user.email == null) {
                        throw FirebaseAuthException(
                          code: 'no-user',
                          message: 'No admin is currently logged in.',
                        );
                      }

                      final credential =
                      EmailAuthProvider.credential(
                        email: user.email!,
                        password: currentPassword,
                      );

                      await user.reauthenticateWithCredential(
                        credential,
                      );

                      await user.updatePassword(newPassword);

                      if (!mounted) return;

                      Navigator.pop(dialogContext);

                      showAdminSnack(
                        context,
                        'Password changed successfully',
                      );
                    } on FirebaseAuthException catch (e) {
                      setDialogState(() {
                        isChanging = false;
                      });

                      String message =
                          'Unable to change password';

                      if (e.code == 'wrong-password' ||
                          e.code == 'invalid-credential') {
                        message = 'Current password is incorrect.';
                      } else if (e.code == 'weak-password') {
                        message =
                        'New password is too weak.';
                      } else if (e.code == 'requires-recent-login') {
                        message =
                        'Please login again and try changing the password.';
                      }

                      showAdminSnack(
                        context,
                        message,
                      );
                    } catch (e) {
                      setDialogState(() {
                        isChanging = false;
                      });

                      showAdminSnack(
                        context,
                        'Something went wrong. Please try again.',
                      );
                    }
                  },
                  child: isChanging
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AdminColors.radius,
          ),
        ),
        title: const Text('Logout?'),
        content: const Text(
          'Are you sure you want to sign out from the admin panel?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        AdminRoutes.login,
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      showAdminSnack(
        context,
        'Logout failed: ${e.message ?? 'Please try again'}',
      );
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
          _SettingsTile(
            icon: Icons.settings_rounded,
            title: 'Settings',
            subtitle: 'Account, security and preferences',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminSettingsScreen(),
                ),
              );
            },
          ),
          _SettingsTile(icon: Icons.notifications_rounded, title: 'Notification Preferences', subtitle: 'Manage alerts and reminders',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationPreferencesScreen(),
                ),
              );
            },
          ),
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
