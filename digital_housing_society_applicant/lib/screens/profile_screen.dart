import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/applicant_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_assets.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../widgets/responsive_shell.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _service = FirestoreService();
  final ImagePicker _picker = ImagePicker();

  ApplicantModel? _applicant;
  _ProfileSnapshot _snapshot = const _ProfileSnapshot();
  bool _loading = true;
  bool _photoSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final uid = user.uid;

    try {
      final applicantDoc = await _service.getApplicant(uid);
      final applicant = applicantDoc.exists
          ? ApplicantModel.fromFirestore(applicantDoc)
          : _fallbackApplicant(user);

      final snapshot = await _ProfileSnapshot.load(uid, _service);

      if (!mounted) return;
      setState(() {
        _applicant = applicant;
        _snapshot = snapshot;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _applicant = _fallbackApplicant(user);
        _loading = false;
      });
    }
  }

  ApplicantModel _fallbackApplicant(User user) {
    return ApplicantModel(
      uid: user.uid,
      fullName: user.displayName ?? 'Applicant',
      email: user.email ?? '',
      phone: '',
      cnic: '',
      dateOfBirth: DateTime.now(),
      address: '',
      city: '',
      createdAt: DateTime.now(),
      profileStatus: user.emailVerified ? 'active' : 'pending',
      notificationsEnabled: true,
      ballotingRegistered: false,
    );
  }

  Uint8List? get _photoBytes {
    final raw = _applicant?.profilePhotoBase64 ?? '';
    if (raw.isEmpty) return null;
    try {
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickProfilePhoto() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 65,
      maxWidth: 720,
      maxHeight: 720,
    );

    if (picked == null) return;

    setState(() => _photoSaving = true);

    try {
      final bytes = await picked.readAsBytes();

      // Firestore documents are limited to ~1 MiB. Keep the encoded image
      // comfortably below that limit because the applicant document has
      // additional fields too.
      if (bytes.length > 520000) {
        _snack(
          'This image is still too large. Please choose a smaller photo.',
        );
        return;
      }

      final encoded = base64Encode(bytes);
      await _service.updateApplicant(
        uid,
        {'profilePhotoBase64': encoded},
      );

      final applicant = _applicant;
      if (applicant != null && mounted) {
        setState(() {
          _applicant = applicant.copyWith(
            profilePhotoBase64: encoded,
          );
        });
      }

      _snack('Profile picture updated.');
    } catch (_) {
      _snack('Could not update profile picture.');
    } finally {
      if (mounted) setState(() => _photoSaving = false);
    }
  }

  Future<void> _editProfile() async {
    final applicant = _applicant;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (applicant == null || uid == null) return;

    final fullName = TextEditingController(text: applicant.fullName);
    final phone = TextEditingController(text: applicant.phone);
    final city = TextEditingController(text: applicant.city);
    final address = TextEditingController(text: applicant.address);

    final updated = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8DCE6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ProfileField(
                    controller: fullName,
                    label: 'Full Name',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                  _ProfileField(
                    controller: phone,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                  ),
                  const SizedBox(height: 12),
                  _ProfileField(
                    controller: city,
                    label: 'City',
                    icon: Icons.location_city_outlined,
                  ),
                  const SizedBox(height: 12),
                  _ProfileField(
                    controller: address,
                    label: 'Address',
                    icon: Icons.home_work_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF315DDC),
                            Color(0xFF7C42EC),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            {
                              'fullName': fullName.text.trim(),
                              'phone': phone.text.trim(),
                              'city': city.text.trim(),
                              'address': address.text.trim(),
                            },
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    fullName.dispose();
    phone.dispose();
    city.dispose();
    address.dispose();

    if (updated == null) return;

    if ((updated['fullName'] ?? '').trim().isEmpty) {
      _snack('Full name is required.');
      return;
    }

    try {
      await _service.updateApplicant(uid, updated);
      if (FirebaseAuth.instance.currentUser?.displayName !=
          updated['fullName']) {
        await FirebaseAuth.instance.currentUser
            ?.updateDisplayName(updated['fullName']);
      }
      await _load();
      _snack('Profile updated successfully.');
    } catch (_) {
      _snack('Profile could not be updated.');
    }
  }

  Future<void> _shareProfile() async {
    final applicant = _applicant;
    if (applicant == null) return;

    final applicationId = _snapshot.applicationId.isEmpty
        ? 'Not assigned'
        : _snapshot.applicationId;

    await Share.share(
      'Digital Housing Society Applicant\n'
      'Name: ${applicant.fullName}\n'
      'City: ${applicant.city}\n'
      'Application ID: $applicationId',
      subject: 'DHS Applicant Profile',
    );
  }

  void _showIdCard() {
    final applicant = _applicant;
    if (applicant == null) return;

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF245CDD),
                Color(0xFF793DEB),
              ],
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: AppColors.deepPurple.withValues(alpha: .28),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                AppAssets.logo,
                height: 54,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.apartment_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 16),
              _ProfileAvatar(
                name: applicant.fullName,
                bytes: _photoBytes,
                radius: 44,
              ),
              const SizedBox(height: 13),
              Text(
                applicant.fullName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Applicant ID: ${_snapshot.applicationId.isEmpty ? applicant.uid.substring(0, applicant.uid.length.clamp(0, 10).toInt()) : _snapshot.applicationId}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .78),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              const _VerifiedChip(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleNotifications(bool value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final applicant = _applicant;
    if (uid == null || applicant == null) return;

    setState(() {
      _applicant = applicant.copyWith(
        notificationsEnabled: value,
      );
    });

    try {
      await _service.updateApplicant(
        uid,
        {'notificationsEnabled': value},
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _applicant = applicant;
      });
      _snack('Notification preference could not be updated.');
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null || email.isEmpty) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _snack('Password reset email sent.');
    } catch (_) {
      _snack('Could not send password reset email.');
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppConstants.loginRoute,
      (_) => false,
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DhsResponsiveShell(
      currentRoute: AppConstants.profileRoute,
      mobileTitle: 'Applicant Profile',
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryPurple,
              ),
            )
          : RefreshIndicator(
              color: AppColors.primaryPurple,
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.sizeOf(context).width >= 980 ? 26 : 14,
                  vertical: 18,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1080),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ProfileHeader(
                            applicant: _applicant!,
                            photoBytes: _photoBytes,
                            photoSaving: _photoSaving,
                            snapshot: _snapshot,
                            onPhotoTap: _pickProfilePhoto,
                            onEdit: _editProfile,
                            onShare: _shareProfile,
                            onIdCard: _showIdCard,
                          ),
                          const SizedBox(height: 18),
                          _ProfileMenuGroup(
                            children: [
                              _ProfileMenuItem(
                                icon: Icons.person_outline_rounded,
                                title: 'About Applicant',
                                subtitle:
                                    'Membership, residency and applicant overview',
                                onTap: () => _showAbout(context),
                              ),
                              _ProfileMenuItem(
                                icon: Icons.badge_outlined,
                                title: 'Personal Details',
                                subtitle:
                                    'Contact, CNIC, date of birth and address',
                                onTap: _editProfile,
                              ),
                              _ProfileMenuItem(
                                icon: Icons.link_rounded,
                                title: 'Linked Accounts / Services',
                                subtitle:
                                    'Application, payment and document services',
                                badge: '${_snapshot.linkedServices} Linked',
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppConstants.myReportsRoute,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _ProfileMenuGroup(
                            children: [
                              _ProfileMenuItem(
                                icon: Icons.favorite_border_rounded,
                                title: 'Saved Items / Favourites',
                                subtitle: 'Your saved DHS plots',
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppConstants.favouritesRoute,
                                ),
                              ),
                              _ProfileMenuItem(
                                icon: Icons.notifications_none_rounded,
                                title: 'Notifications',
                                subtitle:
                                    'Application, payment and balloting alerts',
                                trailing: Switch(
                                  value:
                                      _applicant?.notificationsEnabled ?? true,
                                  onChanged: _toggleNotifications,
                                  activeThumbColor: AppColors.deepPurple,
                                ),
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppConstants.notificationsRoute,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _ProfileMenuGroup(
                            children: [
                              _ProfileMenuItem(
                                icon: Icons.shield_outlined,
                                title: 'Privacy & Security',
                                subtitle:
                                    'Password, privacy policy and account safety',
                                onTap: _sendPasswordReset,
                              ),
                              _ProfileMenuItem(
                                icon: Icons.support_agent_rounded,
                                title: 'Help & Support',
                                subtitle:
                                    'FAQs, contact DHS and support assistance',
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppConstants.contactRoute,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _TrustBanner(
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppConstants.plotsRoute,
                            ),
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Logout'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.errorRed,
                              side: const BorderSide(
                                color: Color(0xFFF3B6B7),
                              ),
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(17),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showAbout(BuildContext context) {
    final applicant = _applicant;
    if (applicant == null) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9DCE6),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'About Applicant',
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                _AboutRow(label: 'Full Name', value: applicant.fullName),
                _AboutRow(label: 'Email', value: applicant.email),
                _AboutRow(label: 'Phone', value: applicant.phone),
                _AboutRow(label: 'CNIC', value: applicant.cnic),
                _AboutRow(label: 'City', value: applicant.city),
                _AboutRow(label: 'Address', value: applicant.address),
                _AboutRow(
                  label: 'Member Since',
                  value: DateFormat('d MMM yyyy').format(applicant.createdAt),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.applicant,
    required this.photoBytes,
    required this.photoSaving,
    required this.snapshot,
    required this.onPhotoTap,
    required this.onEdit,
    required this.onShare,
    required this.onIdCard,
  });

  final ApplicantModel applicant;
  final Uint8List? photoBytes;
  final bool photoSaving;
  final _ProfileSnapshot snapshot;
  final VoidCallback onPhotoTap;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onIdCard;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    final progress = snapshot.completionScore / 1000;

    return Container(
      padding: EdgeInsets.all(compact ? 15 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF315EDA),
            Color(0xFF5E3BDF),
            Color(0xFF7C3FE9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepPurple.withValues(alpha: .22),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Opacity(
              opacity: .10,
              child: Image.asset(
                AppAssets.profileBackground,
                width: compact ? 225 : 390,
                height: compact ? 215 : 280,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          Column(
            children: [
              if (compact)
                Column(
                  children: [
                    _ProfileAvatarWithCamera(
                      applicant: applicant,
                      photoBytes: photoBytes,
                      photoSaving: photoSaving,
                      onPhotoTap: onPhotoTap,
                    ),
                    const SizedBox(height: 10),
                    _ProfileIdentity(
                      applicant: applicant,
                      applicationId: snapshot.applicationId,
                      center: true,
                    ),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _ProfileAvatarWithCamera(
                      applicant: applicant,
                      photoBytes: photoBytes,
                      photoSaving: photoSaving,
                      onPhotoTap: onPhotoTap,
                    ),
                    const SizedBox(width: 22),
                    Expanded(
                      child: _ProfileIdentity(
                        applicant: applicant,
                        applicationId: snapshot.applicationId,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  const columns = 3;
                  const gap = 10.0;
                  final width =
                      (constraints.maxWidth - gap * (columns - 1)) / columns;
                  final buttons = [
                    _HeaderAction(
                      icon: Icons.edit_outlined,
                      label: 'Edit Profile',
                      onTap: onEdit,
                    ),
                    _HeaderAction(
                      icon: Icons.share_outlined,
                      label: 'Share',
                      onTap: onShare,
                    ),
                    _HeaderAction(
                      icon: Icons.badge_outlined,
                      label: 'ID Card',
                      onTap: onIdCard,
                    ),
                  ];
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: buttons
                        .map(
                          (button) => SizedBox(
                            width: width,
                            child: button,
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF171D62).withValues(alpha: .36),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .18),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.workspace_premium_outlined,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Membership Progress • ${_membershipTier(snapshot.completionScore)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0, 1).toDouble(),
                              minHeight: 7,
                              backgroundColor:
                                  Colors.white.withValues(alpha: .18),
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(
                                Color(0xFFB58AFF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${snapshot.completionScore} / 1000',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _membershipTier(int score) {
    if (score >= 850) return 'Platinum Member';
    if (score >= 700) return 'Gold Member';
    if (score >= 450) return 'Silver Member';
    return 'Active Member';
  }
}

class _ProfileAvatarWithCamera extends StatelessWidget {
  const _ProfileAvatarWithCamera({
    required this.applicant,
    required this.photoBytes,
    required this.photoSaving,
    required this.onPhotoTap,
  });

  final ApplicantModel applicant;
  final Uint8List? photoBytes;
  final bool photoSaving;
  final VoidCallback onPhotoTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      height: 108,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: _ProfileAvatar(
              name: applicant.fullName,
              bytes: photoBytes,
              radius: 50,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 2,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 5,
              child: IconButton(
                onPressed: photoSaving ? null : onPhotoTap,
                icon: photoSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.deepPurple,
                        ),
                      )
                    : const Icon(
                        Icons.photo_camera_outlined,
                        color: AppColors.deepPurple,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.name,
    required this.bytes,
    required this.radius,
  });

  final String name;
  final Uint8List? bytes;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: radius - 5,
        backgroundColor: const Color(0xFFE9E3FF),
        backgroundImage: bytes == null ? null : MemoryImage(bytes!),
        child: bytes == null
            ? Text(
                _initials(name),
                style: TextStyle(
                  color: AppColors.deepPurple,
                  fontSize: radius * .55,
                  fontWeight: FontWeight.w900,
                ),
              )
            : null,
      ),
    );
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return 'A';
    return parts.map((part) => part[0].toUpperCase()).join();
  }
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({
    required this.applicant,
    required this.applicationId,
    this.center = false,
  });

  final ApplicantModel applicant;
  final String applicationId;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        const _VerifiedChip(),
        const SizedBox(height: 10),
        Text(
          applicant.fullName.isEmpty ? 'Applicant' : applicant.fullName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: center ? TextAlign.center : TextAlign.left,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 7),
        if (applicant.city.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_city_outlined,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  applicant.city,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .88),
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            'Applicant ID: ${applicationId.isEmpty ? 'Pending assignment' : applicationId}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .88),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _VerifiedChip extends StatelessWidget {
  const _VerifiedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: Colors.white.withValues(alpha: .24),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            color: Color(0xFF9AF2C0),
            size: 17,
          ),
          SizedBox(width: 5),
          Text(
            'Verified Applicant',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: compact ? 16 : 19),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: compact ? 10.5 : 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(
          color: Colors.white.withValues(alpha: .35),
        ),
        backgroundColor: Colors.white.withValues(alpha: .08),
        minimumSize: Size.fromHeight(compact ? 42 : 48),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 14,
          vertical: compact ? 8 : 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}

class _ProfileMenuGroup extends StatelessWidget {
  const _ProfileMenuGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6E7F0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepPurple.withValues(alpha: .055),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: List.generate(children.length, (index) {
          return Column(
            children: [
              children[index],
              if (index != children.length - 1)
                const Divider(
                  height: 1,
                  indent: 76,
                  color: Color(0xFFE8E9F0),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF1EDFF),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0ECFF),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: AppColors.deepPurple,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            trailing ??
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFF7A8293),
                ),
          ],
        ),
      ),
    );
  }
}

class _TrustBanner extends StatelessWidget {
  const _TrustBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFEDE8FF),
            Color(0xFFEAF3FF),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDD5FF)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF315DDC),
                  Color(0xFF7C42EC),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_city_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your trusted partner in digital living',
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Explore verified plots, dealers and transparent DHS services.',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onTap,
            child: const Text('Explore'),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value.trim().isEmpty ? 'Not provided' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSnapshot {
  const _ProfileSnapshot({
    this.applicationId = '',
    this.linkedServices = 0,
    this.completionScore = 250,
  });

  final String applicationId;
  final int linkedServices;
  final int completionScore;

  static Future<_ProfileSnapshot> load(
    String uid,
    FirestoreService service,
  ) async {
    try {
      final application = await service.getApplication(uid);
      final upload = await service.getUpload(uid);
      final payment = await service.getPayment(uid);
      final result = await service.getResultForApplicant(uid);

      var linked = 0;
      var score = 250;

      if (application != null) {
        linked++;
        score += 250;
      }
      if (upload != null) {
        linked++;
        score += 200;
      }
      if (payment != null) {
        linked++;
        score += 200;
      }
      if (result != null) {
        linked++;
        score += 100;
      }

      final appData =
          application?.data() as Map<String, dynamic>? ?? <String, dynamic>{};
      final applicationId = (appData['applicationId'] ??
              appData['serialNumber'] ??
              application?.id ??
              '')
          .toString();

      return _ProfileSnapshot(
        applicationId: applicationId,
        linkedServices: linked,
        completionScore: score.clamp(0, 1000).toInt(),
      );
    } catch (_) {
      return const _ProfileSnapshot();
    }
  }
}
