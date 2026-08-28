import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final _picker = ImagePicker();

  ApplicantModel? _applicant;
  ApplicationModel? _application;
  PaymentModel? _payment;
  String _documentStatus = 'not uploaded';
  String _resultStatus = 'not available';
  bool _loading = true;
  bool _photoSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  ApplicantModel _fallbackApplicant(String uid) {
    final user = FirebaseAuth.instance.currentUser;
    return ApplicantModel(
      uid: uid,
      fullName: user?.displayName ?? '',
      email: user?.email ?? '',
      phone: '',
      cnic: '',
      dateOfBirth: DateTime.now(),
      address: '',
      city: '',
      createdAt: DateTime.now(),
      profileStatus: 'active',
      notificationsEnabled: true,
      ballotingRegistered: false,
    );
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    ApplicantModel? applicant;
    ApplicationModel? application;
    PaymentModel? payment;
    String documentStatus = 'not uploaded';
    String resultStatus = 'not available';
    try {
      final applicantDoc = await _firestoreService.getApplicant(uid);
      applicant = applicantDoc.exists ? ApplicantModel.fromFirestore(applicantDoc) : _fallbackApplicant(uid);
    } catch (_) {
      applicant = _fallbackApplicant(uid);
    }
    try {
      final applicationDoc = await _firestoreService.getApplication(uid);
      application = applicationDoc == null ? null : ApplicationModel.fromFirestore(applicationDoc);
      final base = applicant ?? _fallbackApplicant(uid);
      if (application != null) {
        applicant = base.copyWith(
          fullName: base.fullName.isEmpty ? application.fullName : base.fullName,
          cnic: base.cnic.isEmpty ? application.cnic : base.cnic,
          phone: base.phone.isEmpty ? application.contactNumber : base.phone,
          city: base.city.isEmpty ? application.city : base.city,
          address: base.address.isEmpty ? application.address : base.address,
        );
      }
    } catch (_) {}
    try {
      final paymentDoc = await _firestoreService.getPayment(uid);
      payment = paymentDoc == null ? null : PaymentModel.fromFirestore(paymentDoc);
    } catch (_) {}
    try {
      final uploadDoc = await _firestoreService.getUpload(uid);
      documentStatus = (uploadDoc?.data() as Map<String, dynamic>?)?['verificationStatus']?.toString() ?? 'not uploaded';
    } catch (_) {}
    try {
      final resultDoc = await _firestoreService.getResultForApplicant(uid);
      if (resultDoc != null) {
        final data = resultDoc.data() as Map<String, dynamic>? ?? {};
        resultStatus = data['isSelected'] == true ? 'selected' : 'not selected';
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _applicant = applicant;
      _application = application;
      _payment = payment;
      _documentStatus = documentStatus;
      _resultStatus = resultStatus;
      _loading = false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestoreService.updateApplicant(uid, {'notificationsEnabled': value});
      setState(() => _applicant = _applicant?.copyWith(notificationsEnabled: value));
    } catch (e) {
      _showSnack('Notification setting could not be updated.');
    }
  }

  Future<void> _pickProfilePhoto() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return _showSnack('Please login again.');
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 700, maxHeight: 700);
    if (picked == null) return;
    setState(() => _photoSaving = true);
    try {
      final bytes = await picked.readAsBytes();
      if (bytes.length > 900000) {
        _showSnack('Selected image is too large. Please choose a smaller picture.');
        return;
      }
      final b64 = base64Encode(bytes);
      await _firestoreService.updateApplicant(uid, {'profilePhotoBase64': b64});
      final base = _applicant ?? _fallbackApplicant(uid);
      setState(() => _applicant = base.copyWith(profilePhotoBase64: b64));
      _showSnack('Profile picture updated successfully.');
    } catch (_) {
      _showSnack('Could not save profile photo. Please try again.');
    } finally {
      if (mounted) setState(() => _photoSaving = false);
    }
  }

  Future<void> _removeProfilePhoto() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestoreService.updateApplicant(uid, {'profilePhotoBase64': ''});
      final base = _applicant ?? _fallbackApplicant(uid);
      setState(() => _applicant = base.copyWith(profilePhotoBase64: ''));
      _showSnack('Profile picture removed.');
    } catch (_) {
      _showSnack('Photo could not be removed.');
    }
  }

  void _previewPhoto() {
    final bytes = _photoBytes;
    if (bytes == null) return;
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Image.memory(bytes, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
        ],
      ),
    );
    if (ok != true) return;
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppConstants.loginRoute, (_) => false);
  }

  Uint8List? get _photoBytes {
    final photo = _applicant?.profilePhotoBase64 ?? '';
    if (photo.isEmpty) return null;
    try {
      return base64Decode(photo);
    } catch (_) {
      return null;
    }
  }

  void _showSnack(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)));
    }
    final user = FirebaseAuth.instance.currentUser;
    final name = (_applicant?.fullName ?? user?.displayName ?? '').trim();
    final displayName = name.isEmpty ? 'Applicant' : name;
    final email = (_applicant?.email ?? user?.email ?? '').trim();

    return Scaffold(
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 5),
      body: RefreshIndicator(
        color: AppColors.primaryPurple,
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _ProfileHero(
              name: displayName,
              email: email,
              photoBytes: _photoBytes,
              saving: _photoSaving,
              onUpload: _pickProfilePhoto,
              onPreview: _previewPhoto,
              onRemove: _removeProfilePhoto,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: Column(
                children: [
                  _InfoCard(applicant: _applicant),
                  const SizedBox(height: 18),
                  _MenuCard(
                    onChangePassword: () => _showPasswordSheet(context),
                    notificationsEnabled: _applicant?.notificationsEnabled ?? true,
                    onNotificationChanged: _toggleNotifications,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.errorRed,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Logout'),
                    ),
                  ),
                ],
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
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Change Password', style: AppTextStyles.headingMedium),
                const SizedBox(height: 10),
                Text('For security, enter your current password before setting a new one.', style: AppTextStyles.bodyMedium),
                const SizedBox(height: 18),
                AppTextField(label: 'Current Password', hint: 'Enter current password', controller: current, prefixIcon: Icons.lock_outline_rounded, obscureText: true, validator: (v) => Validators.required(v, 'Current password')),
                const SizedBox(height: 12),
                AppTextField(label: 'New Password', hint: 'Minimum 8 characters', controller: password, prefixIcon: Icons.lock_rounded, obscureText: true, validator: Validators.password),
                const SizedBox(height: 12),
                AppTextField(label: 'Confirm Password', hint: 'Retype new password', controller: confirm, prefixIcon: Icons.lock_reset_rounded, obscureText: true, validator: (v) => v != password.text ? 'Passwords do not match' : null),
                const SizedBox(height: 18),
                PrimaryGradientButton(
                  text: 'Update Password',
                  isLoading: loading,
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    setModalState(() => loading = true);
                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      final email = user?.email;
                      if (user == null || email == null) throw Exception('Please login again.');
                      final credential = EmailAuthProvider.credential(email: email, password: current.text.trim());
                      await user.reauthenticateWithCredential(credential);
                      await user.updatePassword(password.text.trim());
                      if (context.mounted) Navigator.pop(context);
                      if (mounted) _showSnack('Password updated successfully.');
                    } on FirebaseAuthException catch (e) {
                      if (mounted) _showSnack(e.message ?? 'Password could not be updated.');
                    } catch (_) {
                      if (mounted) _showSnack('Password could not be updated. Please try again.');
                    } finally {
                      setModalState(() => loading = false);
                    }
                  },
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.name, required this.email, required this.photoBytes, required this.saving, required this.onUpload, required this.onPreview, required this.onRemove});
  final String name;
  final String email;
  final Uint8List? photoBytes;
  final bool saving;
  final VoidCallback onUpload;
  final VoidCallback onPreview;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty ? 'A' : name.trim().split(RegExp(r'\s+')).map((e) => e[0]).take(2).join().toUpperCase();
    return Container(
      padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 16, 18, 24),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
        image: DecorationImage(image: AssetImage(AppAssets.profileBackground), fit: BoxFit.cover),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: [AppColors.infoBlue.withValues(alpha: .82), AppColors.primaryPurple.withValues(alpha: .80), AppColors.deepPurple.withValues(alpha: .76)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [BoxShadow(color: AppColors.darkNavy.withValues(alpha: .22), blurRadius: 26, offset: const Offset(0, 16))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 58, height: 58, padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18)), child: Image.asset(AppAssets.logo, fit: BoxFit.contain)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Applicant Profile', style: AppTextStyles.headingSmall.copyWith(color: AppColors.white)),
              const SizedBox(height: 2),
              Text('Digital Housing Society', style: AppTextStyles.captionText.copyWith(color: AppColors.white.withValues(alpha: .86))),
            ])),
          ]),
          const SizedBox(height: 22),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Stack(alignment: Alignment.bottomRight, children: [
              GestureDetector(
                onTap: photoBytes == null ? onUpload : onPreview,
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.white, border: Border.all(color: AppColors.white, width: 4), boxShadow: [BoxShadow(color: AppColors.darkNavy.withValues(alpha: .22), blurRadius: 20, offset: const Offset(0, 10))]),
                  child: ClipOval(
                    child: photoBytes == null
                        ? Center(child: Text(initials, style: AppTextStyles.headingLarge.copyWith(color: AppColors.primaryPurple)))
                        : Image.memory(photoBytes!, fit: BoxFit.cover, width: 112, height: 112),
                  ),
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.warningOrange),
                child: saving
                    ? const Padding(padding: EdgeInsets.all(9), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : IconButton(padding: EdgeInsets.zero, icon: const Icon(Icons.camera_alt_rounded, color: AppColors.white, size: 19), onPressed: onUpload),
              ),
            ]),
            const SizedBox(width: 18),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.headingMedium.copyWith(color: AppColors.white, height: 1.15)),
              const SizedBox(height: 7),
              Text(email.isEmpty ? 'No email available' : email, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white.withValues(alpha: .88))),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _HeroAction(label: 'Change', icon: Icons.upload_rounded, onTap: onUpload),
                if (photoBytes != null) _HeroAction(label: 'Preview', icon: Icons.visibility_rounded, onTap: onPreview),
                if (photoBytes != null) _HeroAction(label: 'Remove', icon: Icons.delete_outline_rounded, onTap: onRemove),
              ]),
            ])),
          ]),
        ]),
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: AppColors.white.withValues(alpha: .17), borderRadius: BorderRadius.circular(100), border: Border.all(color: AppColors.white.withValues(alpha: .45))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: AppColors.white, size: 15), const SizedBox(width: 5), Text(label, style: AppTextStyles.captionText.copyWith(color: AppColors.white, fontWeight: FontWeight.w800))]),
      ),
    );
  }
}

class _ProgressOverview extends StatelessWidget {
  const _ProgressOverview({required this.applicationStatus, required this.documentStatus, required this.paymentStatus, required this.ballotingStatus});
  final String applicationStatus;
  final String documentStatus;
  final String paymentStatus;
  final String ballotingStatus;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Application', applicationStatus, Icons.description_rounded),
      ('Documents', documentStatus, Icons.upload_file_rounded),
      ('Payment', paymentStatus, Icons.payment_rounded),
      ('Balloting', ballotingStatus, Icons.casino_rounded),
    ];
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Applicant Progress', style: AppTextStyles.headingSmall),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth < 430 ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 24) / 4;
          return Wrap(
            spacing: 8,
            runSpacing: 10,
            children: items.map((e) {
              final type = badgeTypeFromStatus(e.$2);
              final color = type == StatusBadgeType.success ? AppColors.successGreen : type == StatusBadgeType.warning ? AppColors.warningOrange : type == StatusBadgeType.error ? AppColors.errorRed : AppColors.primaryPurple;
              return SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(18)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(e.$3, color: color, size: 24),
                    const SizedBox(height: 10),
                    Text(e.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.captionText),
                    const SizedBox(height: 4),
                    Text(e.$2.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.captionText.copyWith(color: color, fontWeight: FontWeight.w900)),
                  ]),
                ),
              );
            }).toList(),
          );
        }),
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.applicant});
  final ApplicantModel? applicant;

  @override
  Widget build(BuildContext context) {
    final fullName = _value(applicant?.fullName);
    final cnic = _maskCnic(applicant?.cnic ?? '');
    final phone = _value(applicant?.phone);
    final city = _value(applicant?.city);
    final address = _value(applicant?.address);
    final dob = applicant == null ? '-' : DateFormat('d MMM yyyy').format(applicant!.dateOfBirth);
    final memberSince = applicant == null ? '-' : DateFormat('d MMM yyyy').format(applicant!.createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Personal Details', style: AppTextStyles.headingSmall)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.lightPurpleBackground,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text('Applicant Record', style: AppTextStyles.captionText.copyWith(color: AppColors.deepPurple, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Card(
          child: Column(
            children: [
              _HighlightIdentity(name: fullName, city: city),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoColumns = constraints.maxWidth > 520;
                  final itemWidth = twoColumns ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(width: itemWidth, child: _DetailPill(icon: Icons.badge_rounded, label: 'CNIC', value: cnic)),
                      SizedBox(width: itemWidth, child: _DetailPill(icon: Icons.phone_rounded, label: 'Phone', value: phone)),
                      SizedBox(width: itemWidth, child: _DetailPill(icon: Icons.location_city_rounded, label: 'City', value: city)),
                      SizedBox(width: itemWidth, child: _DetailPill(icon: Icons.cake_rounded, label: 'Date of Birth', value: dob)),
                      SizedBox(width: itemWidth, child: _DetailPill(icon: Icons.event_available_rounded, label: 'Member Since', value: memberSince)),
                      SizedBox(width: itemWidth, child: _DetailPill(icon: Icons.home_work_rounded, label: 'Address', value: address, maxLines: 2)),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _value(String? value) {
    final v = value?.trim() ?? '';
    return v.isEmpty ? '-' : v;
  }

  String _maskCnic(String cnic) {
    final digits = Validators.onlyDigits(cnic);
    if (digits.length != 13) return cnic.isEmpty ? '-' : cnic;
    return '${digits.substring(0, 5)}-XXXXXXX-${digits.substring(12)}';
  }
}

class _HighlightIdentity extends StatelessWidget {
  const _HighlightIdentity({required this.name, required this.city});
  final String name;
  final String city;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.lightPurpleBackground,
            AppColors.infoBlue.withValues(alpha: .10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: .12)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: AppColors.premiumShadow(opacity: .16, blurRadius: 16),
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name == '-' ? 'Applicant information pending' : name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.labelBold.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text(city == '-' ? 'Complete your application to show details' : city, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.captionText),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({required this.icon, required this.label, required this.value, this.maxLines = 1});
  final IconData icon;
  final String label;
  final String value;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: AppColors.primaryPurple.withValues(alpha: .10), borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, color: AppColors.primaryPurple, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.captionText),
                const SizedBox(height: 4),
                Text(value.isEmpty ? '-' : value, maxLines: maxLines, overflow: TextOverflow.ellipsis, style: AppTextStyles.labelBold.copyWith(height: 1.25)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.onChangePassword, required this.notificationsEnabled, required this.onNotificationChanged});
  final VoidCallback onChangePassword;
  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationChanged;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ProfileAction('My Reports', 'Submitted records', Icons.article_rounded, AppColors.deepPurple, () => Navigator.pushNamed(context, AppConstants.myReportsRoute)),
      _ProfileAction('My Application', 'Application status', Icons.home_work_rounded, AppColors.successGreen, () => Navigator.pushNamed(context, AppConstants.applicationRoute)),
      _ProfileAction('My Payments', 'Stripe test records', Icons.account_balance_wallet_rounded, AppColors.warningOrange, () => Navigator.pushNamed(context, AppConstants.paymentRoute)),
      _ProfileAction('My Uploads', 'Documents summary', Icons.folder_rounded, AppColors.infoBlue, () => Navigator.pushNamed(context, AppConstants.uploadRoute)),
      _ProfileAction('Balloting', 'Draw status', Icons.casino_rounded, AppColors.primaryPurple, () => Navigator.pushNamed(context, AppConstants.ballotingRoute)),
      _ProfileAction('Contact Us', 'Society support', Icons.support_agent_rounded, AppColors.primaryPurple, () => Navigator.pushNamed(context, AppConstants.contactRoute)),
      _ProfileAction('FAQs', 'Quick answers', Icons.quiz_rounded, AppColors.infoBlue, () => Navigator.pushNamed(context, AppConstants.faqRoute)),
      _ProfileAction('Privacy', 'Data policy', Icons.privacy_tip_rounded, AppColors.deepPurple, () => Navigator.pushNamed(context, AppConstants.privacyRoute)),
      _ProfileAction('Terms', 'User agreement', Icons.gavel_rounded, AppColors.deepPurple, () => Navigator.pushNamed(context, AppConstants.termsRoute)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Account Services', style: AppTextStyles.headingSmall),
        const SizedBox(height: 14),
        _Card(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth > 700
                  ? (constraints.maxWidth - 24) / 3
                  : constraints.maxWidth > 430
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: actions
                    .map((action) => SizedBox(
                          width: itemWidth,
                          child: _ServiceTile(action: action),
                        ))
                    .toList(),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Text('Security & Preferences', style: AppTextStyles.headingSmall),
        const SizedBox(height: 14),
        _Card(
          child: Column(
            children: [
              _SettingsTile(icon: Icons.lock_rounded, title: 'Change Password', subtitle: 'Update your account password securely', color: AppColors.primaryPurple, onTap: onChangePassword),
              const Divider(height: 22),
              Row(
                children: [
                  _SmallIcon(Icons.notifications_active_rounded, AppColors.primaryPurple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Notifications', style: AppTextStyles.labelBold),
                      const SizedBox(height: 3),
                      Text('Receive application and balloting updates', style: AppTextStyles.captionText),
                    ]),
                  ),
                  Switch(value: notificationsEnabled, activeThumbColor: AppColors.primaryPurple, onChanged: onNotificationChanged),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileAction {
  const _ProfileAction(this.title, this.subtitle, this.icon, this.color, this.onTap);
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.action});
  final _ProfileAction action;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: action.color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: action.color.withValues(alpha: .14)),
        ),
        child: Row(
          children: [
            _SmallIcon(action.icon, action.color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(action.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.labelBold),
                  const SizedBox(height: 3),
                  Text(action.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.captionText),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: action.color),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            _SmallIcon(icon, color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: AppTextStyles.labelBold),
                const SizedBox(height: 3),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.captionText),
              ]),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }
}

class _SmallIcon extends StatelessWidget {
  const _SmallIcon(this.icon, this.color);
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(14)),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderColor), boxShadow: AppColors.premiumShadow(opacity: .24)), child: child);
  }
}
