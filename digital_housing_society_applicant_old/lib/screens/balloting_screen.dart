import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/header_actions.dart';
import '../widgets/illustrations.dart';
import '../widgets/status_badge.dart';

class BallotingScreen extends StatefulWidget {
  const BallotingScreen({super.key});

  @override
  State<BallotingScreen> createState() => _BallotingScreenState();
}

class _BallotingScreenState extends State<BallotingScreen> {
  final _firestoreService = FirestoreService();
  Timer? _timer;
  DateTime? _drawDate;
  String _status = 'upcoming';
  bool _applicationSubmitted = false;
  bool _documentsVerified = false;
  bool _paymentVerified = false;
  bool _registered = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final config = await _firestoreService.getBallotConfig();
      final applicant = await _firestoreService.getApplicant(uid);
      final application = await _firestoreService.getApplication(uid);
      final upload = await _firestoreService.getUpload(uid);
      final payment = await _firestoreService.getPayment(uid);
      final configData = config.exists ? config.data() as Map<String, dynamic>? : FirestoreService.defaultBallotConfig();
      final applicantData = applicant.data() as Map<String, dynamic>?;
      setState(() {
        _drawDate = configData?['drawDate'] is Timestamp ? (configData!['drawDate'] as Timestamp).toDate() : null;
        _status = configData?['status']?.toString() ?? 'upcoming';
        _applicationSubmitted = application != null;
        _documentsVerified = (upload?.data() as Map<String, dynamic>?)?['verificationStatus']?.toString().toLowerCase() == 'verified';
        _paymentVerified = (payment?.data() as Map<String, dynamic>?)?['status']?.toString().toLowerCase() == 'verified';
        _registered = applicantData?['ballotingRegistered'] == true;
      });
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _eligible => _applicationSubmitted && _documentsVerified && _paymentVerified;

  Duration get _remaining {
    if (_drawDate == null) return Duration.zero;
    final diff = _drawDate!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  Future<void> _participate() async {
    if (!_eligible) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Participation'),
        content: const Text('Balloting registration is a one-time action. Do you want to continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirm != true) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestoreService.registerForBalloting(uid);
      if (!mounted) return;
      setState(() => _registered = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registered for balloting successfully.')));
    } catch (e) {
      _showSnack(e.toString());
    }
  }

  void _showSnack(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Balloting'), actions: [Center(child: StatusBadge(text: _status.toUpperCase(), type: badgeTypeFromStatus(_status))), const NotificationBell(), const SizedBox(width: 8)]),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(color: AppColors.deepPurple, borderRadius: BorderRadius.circular(28), boxShadow: AppColors.premiumShadow()),
                  child: Column(
                    children: [
                      SizedBox(height: 150, child: CustomPaint(painter: LotteryDrumPainter(), child: Container())),
                      Text('Digital Balloting Draw', style: AppTextStyles.headingMedium.copyWith(color: AppColors.white)),
                      const SizedBox(height: 8),
                      Text(_drawDate == null ? 'Draw date not configured' : DateFormat('EEEE, d MMMM yyyy • hh:mm a').format(_drawDate!), style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white.withValues(alpha: .86)), textAlign: TextAlign.center),
                      const SizedBox(height: 18),
                      _Countdown(duration: _remaining),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text('Eligibility Checklist', style: AppTextStyles.headingSmall),
                const SizedBox(height: 12),
                _CheckRow(label: 'Application submitted', done: _applicationSubmitted, locked: false),
                _CheckRow(label: 'Documents verified', done: _documentsVerified, locked: !_applicationSubmitted),
                _CheckRow(label: 'Payment verified', done: _paymentVerified, locked: !_documentsVerified),
                const SizedBox(height: 18),
                Text('Live Updates', style: AppTextStyles.headingSmall),
                const SizedBox(height: 12),
                _LiveUpdates(firestoreService: _firestoreService),
                const SizedBox(height: 18),
                PrimaryGradientButton(text: _registered ? 'Registered ✓' : 'Participate', onPressed: _eligible && !_registered ? _participate : null),
              ],
            ),
    );
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown({required this.duration});
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 18) / 4;
        return Row(
          children: [
            SizedBox(width: cardWidth, child: _unit('$days', 'Days')),
            const SizedBox(width: 6),
            SizedBox(width: cardWidth, child: _unit('$hours', 'Hours')),
            const SizedBox(width: 6),
            SizedBox(width: cardWidth, child: _unit('$minutes', 'Minutes')),
            const SizedBox(width: 6),
            SizedBox(width: cardWidth, child: _unit('$seconds', 'Seconds')),
          ],
        );
      },
    );
  }

  Widget _unit(String value, String label) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: AppColors.darkNavy, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [Text(value.padLeft(2, '0'), style: AppTextStyles.headingSmall.copyWith(color: AppColors.gold)), Text(label, style: AppTextStyles.captionText.copyWith(color: AppColors.white.withValues(alpha: .7)))]),
      );
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.label, required this.done, required this.locked});
  final String label;
  final bool done;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.successGreen : locked ? AppColors.inactiveGrey : AppColors.warningOrange;
    final icon = done ? Icons.check_rounded : locked ? Icons.lock_rounded : Icons.schedule_rounded;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.borderColor)),
      child: Row(children: [CircleAvatar(backgroundColor: color, child: Icon(icon, color: AppColors.white)), const SizedBox(width: 12), Expanded(child: Text(label, style: AppTextStyles.labelBold)), StatusBadge(text: done ? 'Done' : locked ? 'Locked' : 'Pending', type: done ? StatusBadgeType.success : locked ? StatusBadgeType.info : StatusBadgeType.warning)]),
    );
  }
}

class _LiveUpdates extends StatelessWidget {
  const _LiveUpdates({required this.firestoreService});
  final FirestoreService firestoreService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.getBallotUpdates(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple));
        final docs = [...?snapshot.data?.docs];
        docs.sort((a, b) {
          final ad = (a.data() as Map<String, dynamic>)['createdAt'];
          final bd = (b.data() as Map<String, dynamic>)['createdAt'];
          final at = ad is Timestamp ? ad.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
          final bt = bd is Timestamp ? bd.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
          return bt.compareTo(at);
        });
        if (docs.isEmpty) return _EmptyState(text: 'No live updates yet');
        return Column(
          children: docs.take(6).map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final time = data['createdAt'] is Timestamp ? (data['createdAt'] as Timestamp).toDate() : DateTime.now();
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.borderColor)),
              child: Row(children: [const Icon(Icons.campaign_rounded, color: AppColors.warningOrange), const SizedBox(width: 10), Expanded(child: Text(data['message']?.toString() ?? '', style: AppTextStyles.bodyMedium)), Text(DateFormat('hh:mm a').format(time), style: AppTextStyles.captionText)]),
            );
          }).toList(),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderColor)), child: Row(children: [const Icon(Icons.info_outline_rounded, color: AppColors.hintText), const SizedBox(width: 10), Expanded(child: Text(text, style: AppTextStyles.bodyMedium))]));
  }
}
