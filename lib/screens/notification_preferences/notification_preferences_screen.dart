import 'package:flutter/material.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_shell.dart';
import '../../widgets/premium_widgets.dart';
import 'preferences_viewmodel.dart';
import 'preferences_widgets.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  final PreferencesViewModel _viewModel = PreferencesViewModel();

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
      title: 'Notification Preferences',
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
                const Text('Notification Settings',
                    style: TextStyle(color: AdminColors.darkText, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text('Choose which alerts you want to receive.',
                    style: TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600)),
                const SizedBox(height: 18),
                PreferenceTile(
                  icon: Icons.notifications_active_rounded,
                  title: 'Notifications',
                  subtitle: 'Enable or disable all admin notifications',
                  value: _viewModel.notificationsEnabled,
                  onChanged: _viewModel.setNotificationsEnabled,
                ),
                const Divider(height: 24),
                PreferenceTile(
                  icon: Icons.person_rounded,
                  title: 'Applicant Updates',
                  subtitle: 'Verification and applicant activity alerts',
                  value: _viewModel.applicantUpdates,
                  enabled: _viewModel.notificationsEnabled,
                  onChanged: _viewModel.setApplicantUpdates,
                ),
                PreferenceTile(
                  icon: Icons.payments_rounded,
                  title: 'Payment Updates',
                  subtitle: 'Payment verification and transaction alerts',
                  value: _viewModel.paymentUpdates,
                  enabled: _viewModel.notificationsEnabled,
                  onChanged: _viewModel.setPaymentUpdates,
                ),
                PreferenceTile(
                  icon: Icons.how_to_vote_rounded,
                  title: 'Balloting Alerts',
                  subtitle: 'Balloting process and result notifications',
                  value: _viewModel.ballotingAlerts,
                  enabled: _viewModel.notificationsEnabled,
                  onChanged: _viewModel.setBallotingAlerts,
                ),
                PreferenceTile(
                  icon: Icons.campaign_rounded,
                  title: 'System Alerts',
                  subtitle: 'Important system and admin notifications',
                  value: _viewModel.systemAlerts,
                  enabled: _viewModel.notificationsEnabled,
                  onChanged: _viewModel.setSystemAlerts,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}