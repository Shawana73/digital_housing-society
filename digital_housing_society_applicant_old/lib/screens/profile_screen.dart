import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/applicant_model.dart';
import '../models/application_model.dart';
import '../models/payment_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/app_assets.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_text_styles.dart';
import '../utils/formatters_validators.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/status_badge.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  ApplicantModel? _applicant;
  ApplicationModel? _application;
  PaymentModel? _payment;
  String _documentStatus = 'not uploaded';
  String _resultStatus = 'not available';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final applicantDoc = await _firestoreService.getApplicant(uid);
      final applicationDoc = await _firestoreService.getApplication(uid);
      final paymentDoc = await _firestoreService.getPayment(uid);
      final uploadDoc = await _firestoreService.getUpload(uid);
      final resultSnap = await FirebaseFirestore.instance.collection('ballot_results').where('applicantId', isEqualTo: uid).limit(1).get();
      setState(() {
        _applicant = applicantDoc.exists ? ApplicantModel.fromFirestore(applicantDoc) : null;
        _application = applicationDoc == null ? null : ApplicationModel.fromFirestore(applicationDoc);
        _payment = paymentDoc == null ? null : PaymentModel.fromFirestore(paymentDoc);
        _documentStatus = (uploadDoc?.data() as Map<String, dynamic>?)?['verificationStatus']?.toString() ?? 'not uploaded';
        if (resultSnap.docs.isNotEmpty) {
          final data = resultSnap.docs.first.data();
          _resultStatus = data['isSelected'] == true ? 'selected' : 'not selected';
        }
      });
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestoreService.updateApplicant(uid, {'notificationsEnabled': value});
      setState(() => _applicant = _applicant?.copyWith(notificationsEnabled: value));
    } catch (e) {
      _showSnack(e.toString());
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout'))],
      ),
    );
    if (ok != true) return;
    await _authService.logout();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out successfully.')));
    Navigator.pushNamedAndRemoveUntil(context, AppConstants.loginRoute, (_) => false);
  }

  void _showSnack(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)));
    }
    final user = FirebaseAuth.instance.currentUser;
    final name = _applicant?.fullName ?? user?.displayName ?? 'Applicant';
    return Scaffold(
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 4),
      body: RefreshIndicator(
        color: AppColors.primaryPurple,
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _Header(name: name, email: _applicant?.email ?? user?.email ?? '', onEdit: () => _showSnack('Profile edit can be connected from admin-approved profile flow.')),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(children: [
                  _InfoCard(applicant: _applicant),
                  const SizedBox(height: 16),
                  _ProgressCard(applicationStatus: _application?.status ?? 'not submitted', documentStatus: _documentStatus, paymentStatus: _payment?.status ?? 'not paid', ballotingStatus: _applicant?.ballotingRegistered == true ? 'registered' : 'not registered', resultStatus: _resultStatus),
                  const SizedBox(height: 16),
                  _MenuCard(onChangePassword: () => _showPasswordSheet(context), notificationsEnabled: _applicant?.notificationsEnabled ?? true, onNotificationChanged: _toggleNotifications),
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity, height: 54, child: FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: AppColors.errorRed, foregroundColor: AppColors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), onPressed: _logout, icon: const Icon(Icons.logout_rounded), label: const Text('Logout'))),
                  const SizedBox(height: 28),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPasswordSheet(BuildContext context) {
    final current = TextEditingController();
    final password = TextEditingController();
    final confirm = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var loading = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(18, 0, 18, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Change Password', style: AppTextStyles.headingMedium),
              const SizedBox(height: 16),
              AppTextField(label: 'Current Password', hint: 'Enter current password', controller: current, obscureText: true, prefixIcon: Icons.lock_clock_rounded, validator: (v) => Validators.required(v, 'Current password')),
              const SizedBox(height: 12),
              AppTextField(label: 'New Password', hint: 'Minimum 8 chars, uppercase, number', controller: password, obscureText: true, prefixIcon: Icons.lock_rounded, validator: Validators.password),
              const SizedBox(height: 12),
              AppTextField(label: 'Confirm Password', hint: 'Repeat new password', controller: confirm, obscureText: true, prefixIcon: Icons.verified_rounded, validator: (v) => v != password.text ? 'Passwords do not match' : null),
              const SizedBox(height: 18),
              PrimaryGradientButton(
                text: 'Update Password',
                isLoading: loading,
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final user = FirebaseAuth.instance.currentUser;
                  if (user?.email == null) return;
                  setModalState(() => loading = true);
                  try {
                    final credential = EmailAuthProvider.credential(email: user!.email!, password: current.text);
                    await user.reauthenticateWithCredential(credential);
                    await _authService.updatePassword(password.text);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Password updated successfully.')));
                  } on FirebaseAuthException catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? e.code)));
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  } finally {
                    if (context.mounted) setModalState(() => loading = false);
                  }
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.email, required this.onEdit});
  final String name;
  final String email;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty ? 'A' : name.trim().split(RegExp(r'\s+')).take(2).map((e) => e[0].toUpperCase()).join();
    return Container(
      height: 312,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
        image: DecorationImage(image: AssetImage(AppAssets.profileBackground), fit: BoxFit.cover),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 46, 18, 22),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.infoBlue.withValues(alpha: .84),
              AppColors.primaryPurple.withValues(alpha: .78),
              AppColors.deepPurple.withValues(alpha: .74),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppColors.white.withValues(alpha: .96), borderRadius: BorderRadius.circular(16)),
                  child: Image.asset(AppAssets.logo, fit: BoxFit.contain),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Applicant Profile', style: AppTextStyles.headingSmall.copyWith(color: AppColors.white)),
                      Text('Digital Housing Society', style: AppTextStyles.captionText.copyWith(color: AppColors.white.withValues(alpha: .86))),
                    ],
                  ),
                ),
                IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded, color: AppColors.white)),
              ],
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white.withValues(alpha: .96),
                    border: Border.all(color: AppColors.white, width: 3),
                    boxShadow: [BoxShadow(color: AppColors.darkNavy.withValues(alpha: .20), blurRadius: 18, offset: const Offset(0, 8))],
                  ),
                  child: Text(initials, style: AppTextStyles.headingMedium.copyWith(color: AppColors.primaryPurple)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.headingMedium.copyWith(color: AppColors.white)),
                      const SizedBox(height: 4),
                      Text(email.isEmpty ? 'No email available' : email, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white.withValues(alpha: .88))),
                      const SizedBox(height: 10),
                      const StatusBadge(text: 'VERIFIED APPLICANT', type: StatusBadgeType.success),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.applicant});
  final ApplicantModel? applicant;

  @override
  Widget build(BuildContext context) {
    return _Card(child: Column(children: [
      _row('CNIC', _maskCnic(applicant?.cnic ?? '')),
      _row('Phone', applicant?.phone ?? '-'),
      _row('City', applicant?.city ?? '-'),
      _row('Date of Birth', applicant == null ? '-' : DateFormat('d MMM yyyy').format(applicant!.dateOfBirth)),
      _row('Member since', applicant == null ? '-' : DateFormat('d MMM yyyy').format(applicant!.createdAt)),
    ]));
  }

  String _maskCnic(String cnic) {
    final digits = Validators.onlyDigits(cnic);
    if (digits.length != 13) return cnic.isEmpty ? '-' : cnic;
    return '${digits.substring(0, 3)}XX-XXXXX${digits.substring(10, 12)}-${digits.substring(12)}';
  }

  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [Text(label, style: AppTextStyles.captionText), const Spacer(), Flexible(child: Text(value, textAlign: TextAlign.right, style: AppTextStyles.labelBold))]));
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.applicationStatus, required this.documentStatus, required this.paymentStatus, required this.ballotingStatus, required this.resultStatus});
  final String applicationStatus;
  final String documentStatus;
  final String paymentStatus;
  final String ballotingStatus;
  final String resultStatus;

  @override
  Widget build(BuildContext context) {
    final items = [('Application', applicationStatus), ('Documents', documentStatus), ('Payment', paymentStatus), ('Balloting', ballotingStatus), ('Result', resultStatus)];
    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('My Progress', style: AppTextStyles.headingSmall),
      const SizedBox(height: 14),
      ...items.map((e) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [CircleAvatar(radius: 13, backgroundColor: _color(e.$2), child: const Icon(Icons.check_rounded, color: AppColors.white, size: 15)), const SizedBox(width: 10), Expanded(child: Text(e.$1, style: AppTextStyles.labelBold)), StatusBadge(text: e.$2.toUpperCase(), type: badgeTypeFromStatus(e.$2))]))),
    ]));
  }

  Color _color(String status) {
    final type = badgeTypeFromStatus(status);
    if (type == StatusBadgeType.success) return AppColors.successGreen;
    if (type == StatusBadgeType.warning) return AppColors.warningOrange;
    if (type == StatusBadgeType.error) return AppColors.errorRed;
    return AppColors.primaryPurple;
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.onChangePassword, required this.notificationsEnabled, required this.onNotificationChanged});
  final VoidCallback onChangePassword;
  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationChanged;

  @override
  Widget build(BuildContext context) {
    return _Card(child: Column(children: [
      _menu(context, 'My Application', Icons.house_rounded, AppColors.successGreen, () => Navigator.pushNamed(context, AppConstants.applicationRoute)),
      _menu(context, 'My Payment', Icons.account_balance_wallet_rounded, AppColors.warningOrange, () => Navigator.pushNamed(context, AppConstants.paymentRoute)),
      _menu(context, 'My Uploads', Icons.folder_rounded, AppColors.infoBlue, () => Navigator.pushNamed(context, AppConstants.uploadRoute)),
      _menu(context, 'Notifications', Icons.notifications_rounded, AppColors.primaryPurple, () => Navigator.pushNamed(context, AppConstants.notificationsRoute)),
      ListTile(contentPadding: EdgeInsets.zero, leading: _icon(Icons.lock_rounded, AppColors.primaryPurple), title: Text('Change Password', style: AppTextStyles.labelBold), onTap: onChangePassword),
      ListTile(contentPadding: EdgeInsets.zero, leading: _icon(Icons.notifications_active_rounded, AppColors.primaryPurple), title: Text('Notification Toggle', style: AppTextStyles.labelBold), trailing: Switch(value: notificationsEnabled, activeThumbColor: AppColors.primaryPurple, onChanged: onNotificationChanged)),
    ]));
  }

  Widget _menu(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) => ListTile(contentPadding: EdgeInsets.zero, leading: _icon(icon, color), title: Text(title, style: AppTextStyles.labelBold), trailing: const Icon(Icons.chevron_right_rounded), onTap: onTap);
  Widget _icon(IconData icon, Color color) => Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color));
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderColor), boxShadow: AppColors.premiumShadow(opacity: .28)), child: child);
  }
}
