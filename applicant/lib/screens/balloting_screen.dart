import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/result_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_assets.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_text_styles.dart';
import '../widgets/responsive_shell.dart';
import '../widgets/status_badge.dart';

class BallotingScreen extends StatefulWidget {
  const BallotingScreen({super.key});

  @override
  State<BallotingScreen> createState() => _BallotingScreenState();
}

class _BallotingScreenState extends State<BallotingScreen>
    with TickerProviderStateMixin {
  final _firestoreService = FirestoreService();

  late final AnimationController _confetti;

  ResultModel? _result;
  Map<String, dynamic>? _eligibility;
  bool _resultLoading = true;

  @override
  void initState() {
    super.initState();
    _confetti = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _loadApplicantBallotingData();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _loadApplicantBallotingData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _resultLoading = false);
      return;
    }

    try {
      final resultDoc = await _firestoreService.getResultForApplicant(uid);
      final eligibility =
      await _firestoreService.getBallotingEligibility(uid);

      if (!mounted) return;
      setState(() {
        _result = resultDoc == null
            ? null
            : ResultModel.fromFirestore(resultDoc);
        _eligibility = eligibility;
      });
    } catch (_) {
      // Official data stays empty until Firestore returns/publishes it.
    } finally {
      if (mounted) setState(() => _resultLoading = false);
    }
  }

  DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return DhsResponsiveShell(
      currentRoute: AppConstants.ballotingRoute,
      mobileTitle: '',
      showMobileAppBar: false,
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ballot_config')
            .doc('main')
            .snapshots(),
        builder: (context, snapshot) {
          // IMPORTANT: do not assume a temporary status while Firestore loads.
          // This removes the 1-second wrong-screen flash.
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData ||
              _resultLoading) {
            return const _BallotingLoadingView();
          }

          final configExists = snapshot.data?.exists == true;
          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};

          final configuredStatus = configExists
              ? _normalizeStatus(data['status']?.toString() ?? 'upcoming')
              : 'none';
          final status = _effectiveStatus(configuredStatus);
          final drawDate = _date(data['drawDate']);


          return RefreshIndicator(
            color: AppColors.deepPurple,
            onRefresh: _loadApplicantBallotingData,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                MediaQuery.sizeOf(context).width >= 980 ? 24 : 14,
                14,
                MediaQuery.sizeOf(context).width >= 980 ? 24 : 14,
                28,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _stateWidget(status, data, drawDate),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _stateWidget(
      String status,
      Map<String, dynamic> data,
      DateTime? drawDate,
      ) {
    // Published official result wins over older eligibility data.
    if (status == 'winner') {
      return _WinnerState(
        key: const ValueKey('winner'),
        data: data,
        result: _result,
        confetti: _confetti,
      );
    }

    if (status == 'notselected') {
      return _NotSelectedState(
        key: const ValueKey('notselected'),
        data: data,
        result: _result,
      );
    }

    if (status == 'completed') {
      return _CompletedState(
        key: const ValueKey('completed'),
        data: data,
        result: _result,
      );
    }

    if (status == 'none') {
      return const _NoBallotingState(key: ValueKey('none'));
    }

    if (_eligibility?['eligible'] != true && status != 'upcoming') {
      return _EligibilityState(
        key: const ValueKey('eligibility'),
        data: _eligibility ?? const {},
      );
    }

    if (status == 'live') {
      return _LiveState(
        key: const ValueKey('live'),
        data: data,
        eligibility: _eligibility ?? const {},
      );
    }

    return _UpcomingState(
      key: const ValueKey('upcoming'),
      data: data,
      drawDate: drawDate,
      eligibility: _eligibility ?? const {},
    );
  }

  String _effectiveStatus(String configured) {
    if (configured == 'upcoming' ||
        configured == 'live' ||
        configured == 'none') {
      return configured;
    }

    if (_result != null) {
      return _result!.isSelected ? 'winner' : 'notselected';
    }

    if (configured == 'winner' || configured == 'notselected') {
      return 'completed';
    }

    return configured;
  }

  String _normalizeStatus(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll('_', '')
        .replaceAll('-', '')
        .replaceAll(' ', '')
        .trim();

    if (normalized == 'inactive' ||
        normalized == 'noschedule' ||
        normalized == 'noscheduled' ||
        normalized == 'none') {
      return 'none';
    }
    if (normalized == 'selected' || normalized == 'winner') {
      return 'winner';
    }
    if (normalized == 'notselected' ||
        normalized == 'unsuccessful' ||
        normalized == 'failed') {
      return 'notselected';
    }
    if (normalized == 'complete' || normalized == 'completed') {
      return 'completed';
    }
    if (normalized == 'live' || normalized == 'running') {
      return 'live';
    }
    return 'upcoming';
  }
}

// -----------------------------------------------------------------------------
// LOADING / EMPTY
// -----------------------------------------------------------------------------

class _BallotingLoadingView extends StatelessWidget {
  const _BallotingLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(42),
        child: CircularProgressIndicator(color: AppColors.deepPurple),
      ),
    );
  }
}

class _NoBallotingState extends StatelessWidget {
  const _NoBallotingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _PlainTopControls(
          badgeText: 'NO ACTIVE DRAW',
          badgeType: StatusBadgeType.warning,
        ),
        const SizedBox(height: 14),
        _Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.lightPurpleBackground,
                  ),
                  child: const Icon(
                    Icons.event_busy_rounded,
                    color: AppColors.deepPurple,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'No Balloting Scheduled',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headingMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'There is currently no active or upcoming balloting session. You will be notified when the next round is announced.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// ELIGIBILITY REVIEW
// -----------------------------------------------------------------------------

class _EligibilityState extends StatelessWidget {
  const _EligibilityState({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _PlainTopControls(
          badgeText: 'UNDER REVIEW',
          badgeType: StatusBadgeType.warning,
        ),
        const SizedBox(height: 14),
        _Card(
          child: Column(
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.warningLightBackground,
                ),
                child: const Icon(
                  Icons.manage_search_rounded,
                  color: AppColors.warningOrange,
                  size: 42,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Eligibility Under Review',
                textAlign: TextAlign.center,
                style: AppTextStyles.headingMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Your application, documents and payment details are being verified before the official draw.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _EligibilityProgressCard(data: data),
      ],
    );
  }
}

class _EligibilityProgressCard extends StatelessWidget {
  const _EligibilityProgressCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review Progress', style: AppTextStyles.headingSmall),
          const SizedBox(height: 16),
          _StatusRow(
            icon: Icons.description_outlined,
            title: 'Application',
            value: _friendlyStatus(data['applicationStatus']),
            rawStatus: data['applicationStatus']?.toString() ?? '',
          ),
          const Divider(height: 22),
          _StatusRow(
            icon: Icons.folder_copy_outlined,
            title: 'Documents',
            value: _friendlyStatus(data['documentsStatus']),
            rawStatus: data['documentsStatus']?.toString() ?? '',
          ),
          const Divider(height: 22),
          _StatusRow(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Payment',
            value: _friendlyStatus(data['paymentStatus']),
            rawStatus: data['paymentStatus']?.toString() ?? '',
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// UPCOMING
// -----------------------------------------------------------------------------

class _UpcomingState extends StatelessWidget {
  const _UpcomingState({
    super.key,
    required this.data,
    required this.drawDate,
    required this.eligibility,
  });

  final Map<String, dynamic> data;
  final DateTime? drawDate;
  final Map<String, dynamic> eligibility;

  @override
  Widget build(BuildContext context) {
    final project = _text(data, 'projectName', 'Official Housing Balloting');
    final block = _text(data, 'block', 'Block');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PhotoHeader(
          image: AppAssets.applyBackground,
          badge: 'UPCOMING BALLOTING',
          badgeType: StatusBadgeType.warning,
          title: '$project - $block',
          subtitle: drawDate == null
              ? 'Draw date will be announced by society administration.'
              : DateFormat('EEEE, d MMMM yyyy • hh:mm a').format(drawDate!),
        ),
        const SizedBox(height: 18),
        _CountdownCard(drawDate: drawDate),
        const SizedBox(height: 18),
        const _ProfessionalSessionCard(
          title: 'Official draw is being prepared',
          subtitle:
          'Only verified applications will be included in the balloting session.',
          icon: Icons.event_available_rounded,
        ),
        const SizedBox(height: 18),
        _BeforeDrawCard(eligibility: eligibility),
      ],
    );
  }
}

class _CountdownCard extends StatefulWidget {
  const _CountdownCard({required this.drawDate});

  final DateTime? drawDate;

  @override
  State<_CountdownCard> createState() => _CountdownCardState();
}

class _CountdownCardState extends State<_CountdownCard> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _syncCountdown();
  }

  @override
  void didUpdateWidget(covariant _CountdownCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.drawDate != widget.drawDate) {
      _syncCountdown();
    }
  }

  void _syncCountdown() {
    _timer?.cancel();

    final drawDate = widget.drawDate;
    if (drawDate == null) {
      _remaining = Duration.zero;
      return;
    }

    final firstDifference = drawDate.difference(DateTime.now());
    _remaining =
    firstDifference.isNegative ? Duration.zero : firstDifference;

    if (_remaining == Duration.zero) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      final difference = drawDate.difference(DateTime.now());
      final next = difference.isNegative ? Duration.zero : difference;

      setState(() => _remaining = next);

      if (next == Duration.zero) {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final values = [
      (_remaining.inDays, 'DAYS'),
      (_remaining.inHours.remainder(24), 'HOURS'),
      (_remaining.inMinutes.remainder(60), 'MINUTES'),
      (_remaining.inSeconds.remainder(60), 'SECONDS'),
    ];

    return RepaintBoundary(
      child: _Card(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
        child: Row(
          children: [
            for (var index = 0; index < values.length; index++) ...[
              Expanded(
                child: Column(
                  children: [
                    Text(
                      values[index].$1.toString().padLeft(2, '0'),
                      style: AppTextStyles.headingMedium.copyWith(
                        color: AppColors.deepPurple,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      values[index].$2,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.captionText.copyWith(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (index != values.length - 1)
                Container(
                  width: 1,
                  height: 48,
                  color: AppColors.borderColor,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BeforeDrawCard extends StatelessWidget {
  const _BeforeDrawCard({required this.eligibility});

  final Map<String, dynamic> eligibility;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Before the Draw', style: AppTextStyles.headingMedium),
          const SizedBox(height: 14),
          _StatusRow(
            icon: Icons.description_outlined,
            title: 'Application',
            subtitle: 'Your application status',
            value: _friendlyStatus(eligibility['applicationStatus']),
            rawStatus: eligibility['applicationStatus']?.toString() ?? '',
          ),
          const Divider(height: 22),
          _StatusRow(
            icon: Icons.folder_outlined,
            title: 'Documents',
            subtitle: 'Required documents status',
            value: _friendlyStatus(eligibility['documentsStatus']),
            rawStatus: eligibility['documentsStatus']?.toString() ?? '',
          ),
          const Divider(height: 22),
          _StatusRow(
            icon: Icons.credit_card_rounded,
            title: 'Payment',
            subtitle: 'Payment verification status',
            value: _friendlyStatus(eligibility['paymentStatus']),
            rawStatus: eligibility['paymentStatus']?.toString() ?? '',
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// LIVE
// -----------------------------------------------------------------------------

class _LiveState extends StatelessWidget {
  const _LiveState({
    super.key,
    required this.data,
    required this.eligibility,
  });

  final Map<String, dynamic> data;
  final Map<String, dynamic> eligibility;

  @override
  Widget build(BuildContext context) {
    final project = _text(data, 'projectName', 'Official Housing Balloting');
    final block = _text(data, 'block', 'Block');
    final current = _text(data, 'currentNumber', '----');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PhotoHeader(
          image: AppAssets.heroBackground,
          badge: 'LIVE NOW',
          badgeType: StatusBadgeType.success,
          title: 'Live Balloting Session',
          subtitle: '$project - $block',
        ),
        const SizedBox(height: 18),
        _LiveSessionCard(data: data),
        const SizedBox(height: 18),
        _DrawNumberCard(
          title: 'Current Draw Number',
          number: current,
        ),
        const SizedBox(height: 18),
        _LiveFeedCard(feed: data['liveFeed']),
        const SizedBox(height: 18),
        const _LiveResultsPanel(),
      ],
    );
  }
}

class _LiveSessionCard extends StatelessWidget {
  const _LiveSessionCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GradientIconBox(
                icon: Icons.videocam_rounded,
                size: 58,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Balloting Session',
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _text(
                        data,
                        'message',
                        'The official housing balloting draw is currently in progress.',
                      ),
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: MediaQuery.sizeOf(context).width < 560 ? 170 : 220,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              image: const DecorationImage(
                image: AssetImage(AppAssets.courtyardBackground),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.darkNavy.withValues(alpha: .12),
                    AppColors.darkNavy.withValues(alpha: .62),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'OFFICIAL LIVE DRAW',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: AppColors.white,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        color: Colors.black.withValues(alpha: .18),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawNumberCard extends StatelessWidget {
  const _DrawNumberCard({required this.title, required this.number});

  final String title;
  final String number;

  @override
  Widget build(BuildContext context) {
    final clean = number.replaceAll(RegExp(r'[^0-9]'), '');
    final digits = clean.isEmpty
        ? ['-', '-', '-', '-']
        : clean.padLeft(4, '0').split('').take(6).toList();

    return _Card(
      child: Column(
        children: [
          Text(title, style: AppTextStyles.headingSmall),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: digits
                .map(
                  (digit) => Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 100),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFF2F6FF),
                        Color(0xFFF1EAFF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.lavender.withValues(alpha: .38),
                    ),
                  ),
                  child: Text(
                    digit,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headingMedium.copyWith(
                      color: AppColors.deepPurple,
                      fontSize: 30,
                    ),
                  ),
                ),
              ),
            )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _LiveFeedCard extends StatelessWidget {
  const _LiveFeedCard({required this.feed});

  final dynamic feed;

  @override
  Widget build(BuildContext context) {
    final items = feed is List ? feed : const [];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SoftIconCircle(icon: Icons.podcasts_rounded),
              const SizedBox(width: 10),
              Text('Official Live Feed', style: AppTextStyles.headingSmall),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Text(
              'Live updates will appear here during the official draw.',
              style: AppTextStyles.bodyMedium,
            )
          else
            ...items.take(6).map((item) {
              final map = item is Map ? item : {};
              return Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        (map['text'] ?? '').toString(),
                        style: AppTextStyles.labelBold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (map['time'] ?? '').toString(),
                      style: AppTextStyles.captionText.copyWith(
                        color: AppColors.deepPurple,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _LiveResultsPanel extends StatelessWidget {
  const _LiveResultsPanel();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ballot_live_results')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = [...?snapshot.data?.docs];

        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aCreated = aData['createdAt'];
          final bCreated = bData['createdAt'];
          final aTime = aCreated is Timestamp
              ? aCreated.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = bCreated is Timestamp
              ? bCreated.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });

        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Live Results', style: AppTextStyles.headingSmall),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.errorRed,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppConstants.resultRoute,
                    ),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (docs.isEmpty)
                Text(
                  'Live result entries will appear here when published by administration.',
                  style: AppTextStyles.bodyMedium,
                )
              else
                ...docs.take(8).map((doc) {
                  final row =
                      doc.data() as Map<String, dynamic>? ?? const {};
                  return _LiveResultTile(
                    applicationNo: _text(
                      row,
                      'applicationNumber',
                      _text(row, 'applicationNo', '-'),
                    ),
                    cnic: _maskCnic(_text(row, 'cnic', '-')),
                    plot: _text(row, 'plotNumber', '-'),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _LiveResultTile extends StatelessWidget {
  const _LiveResultTile({
    required this.applicationNo,
    required this.cnic,
    required this.plot,
  });

  final String applicationNo;
  final String cnic;
  final String plot;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 560;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: mobile
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(applicationNo, style: AppTextStyles.labelBold),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(cnic, style: AppTextStyles.captionText),
              ),
              _AllocatedPill(plot: plot),
            ],
          ),
        ],
      )
          : Row(
        children: [
          const _SoftIconCircle(
            icon: Icons.home_work_outlined,
            size: 38,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(applicationNo, style: AppTextStyles.labelBold),
                const SizedBox(height: 2),
                Text(cnic, style: AppTextStyles.captionText),
              ],
            ),
          ),
          _AllocatedPill(plot: plot),
        ],
      ),
    );
  }
}

class _AllocatedPill extends StatelessWidget {
  const _AllocatedPill({required this.plot});

  final String plot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.successLightBackground,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: AppColors.successGreen,
          ),
          const SizedBox(width: 5),
          Text(
            plot,
            style: AppTextStyles.captionText.copyWith(
              color: AppColors.successGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// COMPLETED - RESULT NOT YET PUBLISHED
// -----------------------------------------------------------------------------

class _CompletedState extends StatelessWidget {
  const _CompletedState({
    super.key,
    required this.data,
    required this.result,
  });

  final Map<String, dynamic> data;
  final ResultModel? result;

  @override
  Widget build(BuildContext context) {
    final project = _text(data, 'projectName', 'Official Housing Balloting');
    final block = _text(data, 'block', '-');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PhotoHeader(
          image: AppAssets.authBackground,
          badge: 'COMPLETED',
          badgeType: StatusBadgeType.success,
          title: 'Balloting Completed',
          subtitle: '$project - $block',
          imageAlignment: Alignment.centerRight,
        ),
        const SizedBox(height: 18),
        _DrawSummaryCard(
          block: block,
          eligibleApplications: _text(
            data,
            'totalEligibleApplications',
            _text(data, 'totalApplicants', '0'),
          ),
          totalPlots: _text(data, 'totalPlots', '0'),
          selected: _text(
            data,
            'selectedApplications',
            _text(data, 'totalWinners', '0'),
          ),
          notSelected: _text(data, 'notSelectedApplications', '0'),
          resultText: result == null
              ? 'Pending publication'
              : result!.isSelected
              ? 'Selected'
              : 'Not selected',
        ),
        const SizedBox(height: 18),
        _TimelinePanel(timeline: data['timeline']),
        const SizedBox(height: 18),
        const _WhatHappensNextCard(),
      ],
    );
  }
}

class _DrawSummaryCard extends StatelessWidget {
  const _DrawSummaryCard({
    required this.block,
    required this.eligibleApplications,
    required this.totalPlots,
    required this.selected,
    required this.notSelected,
    required this.resultText,
  });

  final String block;
  final String eligibleApplications;
  final String totalPlots;
  final String selected;
  final String notSelected;
  final String resultText;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SoftIconCircle(icon: Icons.assignment_outlined),
              const SizedBox(width: 10),
              Text('Draw Summary', style: AppTextStyles.headingMedium),
            ],
          ),
          const SizedBox(height: 14),
          _SummaryLine(
            icon: Icons.apartment_rounded,
            label: 'Block',
            value: block,
          ),
          _SummaryLine(
            icon: Icons.groups_outlined,
            label: 'Eligible Applications',
            value: eligibleApplications,
          ),
          _SummaryLine(
            icon: Icons.location_on_outlined,
            label: 'Total Plots',
            value: totalPlots,
          ),
          _SummaryLine(
            icon: Icons.check_box_outlined,
            label: 'Selected',
            value: selected,
            valueColor: AppColors.deepPurple,
          ),
          _SummaryLine(
            icon: Icons.cancel_outlined,
            label: 'Not Selected',
            value: notSelected,
          ),
          _SummaryLine(
            icon: Icons.emoji_events_outlined,
            label: 'Your Result',
            value: resultText,
            valueColor: AppColors.deepPurple,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _TimelinePanel extends StatelessWidget {
  const _TimelinePanel({required this.timeline});

  final dynamic timeline;

  @override
  Widget build(BuildContext context) {
    final items = timeline is List ? timeline : const [];

    if (items.isEmpty) {
      return _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _SoftIconCircle(icon: Icons.calendar_month_outlined),
                const SizedBox(width: 10),
                Text('Timeline', style: AppTextStyles.headingMedium),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Timeline will appear when published by administration.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 18),
            const _DefaultCompletedTimeline(),
          ],
        ),
      );
    }

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Timeline', style: AppTextStyles.headingMedium),
          const SizedBox(height: 16),
          ...items.map((item) {
            final map = item is Map ? item : {};
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.successGreen,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      (map['title'] ?? '').toString(),
                      style: AppTextStyles.labelBold,
                    ),
                  ),
                  Text(
                    (map['date'] ?? '').toString(),
                    style: AppTextStyles.captionText,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DefaultCompletedTimeline extends StatelessWidget {
  const _DefaultCompletedTimeline();

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('Scheduled', Icons.event_outlined),
      ('Verified', Icons.verified_user_outlined),
      ('Draw Conducted', Icons.gavel_rounded),
      ('Results Pending', Icons.schedule_rounded),
    ];

    final compact = MediaQuery.sizeOf(context).width < 560;

    if (compact) {
      return Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    _TimelineCircle(
                      icon: steps[i].$2,
                      active: i < 3,
                    ),
                    if (i != steps.length - 1)
                      Container(
                        width: 2,
                        height: 34,
                        color: i < 2
                            ? AppColors.primaryPurple
                            : AppColors.borderColor,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      steps[i].$1,
                      style: AppTextStyles.labelBold,
                    ),
                  ),
                ),
              ],
            ),
        ],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                _TimelineCircle(icon: steps[i].$2, active: i < 3),
                const SizedBox(height: 8),
                Text(
                  steps[i].$1,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.captionText.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (i != steps.length - 1)
            Expanded(
              child: Container(
                height: 2,
                color: i < 2
                    ? AppColors.primaryPurple
                    : AppColors.borderColor,
              ),
            ),
        ],
      ],
    );
  }
}

class _TimelineCircle extends StatelessWidget {
  const _TimelineCircle({required this.icon, required this.active});

  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: active ? AppColors.primaryGradient : null,
        color: active ? null : Colors.white,
        border: Border.all(
          color: active ? Colors.transparent : AppColors.deepPurple,
        ),
      ),
      child: Icon(
        icon,
        color: active ? Colors.white : AppColors.deepPurple,
        size: 21,
      ),
    );
  }
}

class _WhatHappensNextCard extends StatelessWidget {
  const _WhatHappensNextCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SoftIconCircle(icon: Icons.campaign_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What happens next?', style: AppTextStyles.headingSmall),
                const SizedBox(height: 8),
                Text(
                  '• Results will be published by the administration.\n• You will be notified as soon as your result is available.',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// WINNER
// -----------------------------------------------------------------------------

class _WinnerState extends StatelessWidget {
  const _WinnerState({
    super.key,
    required this.data,
    required this.result,
    required this.confetti,
  });

  final Map<String, dynamic> data;
  final ResultModel? result;
  final Animation<double> confetti;

  @override
  Widget build(BuildContext context) {
    final plotNumber =
        result?.plotNumber ?? _text(data, 'selectedPlotNumber', '');
    final applicationNo =
        result?.serialNumber ?? _text(data, 'selectedApplicationId', '');
    final block = result?.plotLocation ?? _text(data, 'block', '-');

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: confetti,
              builder: (_, __) => CustomPaint(
                painter: _ElegantConfettiPainter(confetti.value),
              ),
            ),
          ),
        ),
        Column(
          children: [
            const _PlainTopControls(
              badgeText: 'SELECTED',
              badgeType: StatusBadgeType.success,
            ),
            const SizedBox(height: 18),
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.successGreen,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.successGreen.withValues(alpha: .24),
                    blurRadius: 34,
                    spreadRadius: 7,
                  ),
                ],
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: AppColors.white,
                size: 58,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Congratulations!',
              textAlign: TextAlign.center,
              style: AppTextStyles.headingMedium,
            ),
            const SizedBox(height: 4),
            ShaderMask(
              shaderCallback: (bounds) => AppColors.primaryGradient
                  .createShader(Offset.zero & bounds.size),
              child: Text(
                'You Won',
                style: AppTextStyles.headingLarge.copyWith(
                  color: Colors.white,
                  fontSize: MediaQuery.sizeOf(context).width < 560 ? 42 : 48,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Your application has been selected in the official balloting.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _SelectionDetailsCard(
              applicationNo: applicationNo.isEmpty ? '-' : applicationNo,
              block: block,
              plotNumber: plotNumber.isEmpty ? '-' : plotNumber,
            ),
            const SizedBox(height: 18),
            _NextStepCard(
              onPressed: () => Navigator.pushNamed(
                context,
                AppConstants.resultRoute,
              ),
            ),
            const SizedBox(height: 18),
            const _NotificationHintCard(
              text:
              'You will be notified of payment instructions and next steps through official DHS notifications.',
            ),
          ],
        ),
      ],
    );
  }
}

class _SelectionDetailsCard extends StatelessWidget {
  const _SelectionDetailsCard({
    required this.applicationNo,
    required this.block,
    required this.plotNumber,
  });

  final String applicationNo;
  final String block;
  final String plotNumber;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SoftIconCircle(icon: Icons.description_outlined),
              const SizedBox(width: 10),
              Text('Selection Details', style: AppTextStyles.headingMedium),
            ],
          ),
          const SizedBox(height: 14),
          _SimpleDetailRow(label: 'Application No.', value: applicationNo),
          _SimpleDetailRow(label: 'Block', value: block),
          _SimpleDetailRow(label: 'Plot Number', value: plotNumber),
          const _SimpleDetailRow(
            label: 'Status',
            value: 'Selected',
            valueColor: AppColors.successGreen,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _NextStepCard extends StatelessWidget {
  const _NextStepCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _GradientIconBox(icon: Icons.handshake_rounded),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Next Step', style: AppTextStyles.headingMedium),
                    const SizedBox(height: 6),
                    Text(
                      'Society administration will contact selected applicants for further processing.',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('View Allotment Details'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: AppTextStyles.buttonText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// NOT SELECTED
// -----------------------------------------------------------------------------

class _NotSelectedState extends StatelessWidget {
  const _NotSelectedState({
    super.key,
    required this.data,
    required this.result,
  });

  final Map<String, dynamic> data;
  final ResultModel? result;

  @override
  Widget build(BuildContext context) {
    final applicationNo =
        result?.serialNumber ?? _text(data, 'applicationNumber', '');
    final block = result?.plotLocation ?? _text(data, 'block', '-');
    final drawn = _text(data, 'drawnNumber', result?.serialNumber ?? '-');

    return Column(
      children: [
        const _PlainTopControls(
          badgeText: 'RESULT',
          badgeType: StatusBadgeType.error,
        ),
        const SizedBox(height: 18),
        Container(
          width: 102,
          height: 102,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.lightPurpleBackground,
            border: Border.all(color: Colors.white, width: 5),
            boxShadow: AppColors.premiumShadow(opacity: .18),
          ),
          child: const Icon(
            Icons.close_rounded,
            color: AppColors.deepPurple,
            size: 54,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Not Selected',
          textAlign: TextAlign.center,
          style: AppTextStyles.headingLarge.copyWith(
            color: AppColors.errorRed,
            fontSize: 34,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Thank you for participating in the official balloting.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: 24),
        _DrawDetailsCard(
          applicationNo: applicationNo.isEmpty ? '-' : applicationNo,
          block: block,
          drawNumber: drawn,
        ),
        const SizedBox(height: 18),
        const _ProfessionalSessionCard(
          title: 'Stay Connected',
          subtitle:
          'Future projects and scheme updates will appear in notifications.',
          icon: Icons.notifications_active_rounded,
        ),
        const SizedBox(height: 18),
        const _NotificationHintCard(
          text: 'You may apply again in future balloting rounds.',
          icon: Icons.sync_rounded,
        ),
      ],
    );
  }
}

class _DrawDetailsCard extends StatelessWidget {
  const _DrawDetailsCard({
    required this.applicationNo,
    required this.block,
    required this.drawNumber,
  });

  final String applicationNo;
  final String block;
  final String drawNumber;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Draw Details', style: AppTextStyles.headingMedium),
          const SizedBox(height: 14),
          _SimpleDetailRow(label: 'Application No.', value: applicationNo),
          _SimpleDetailRow(label: 'Block', value: block),
          _SimpleDetailRow(label: 'Draw Number', value: drawNumber),
          const _SimpleDetailRow(
            label: 'Status',
            value: 'Not Selected',
            valueColor: AppColors.errorRed,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SHARED VISUALS
// -----------------------------------------------------------------------------

class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({
    required this.image,
    required this.badge,
    required this.badgeType,
    required this.title,
    required this.subtitle,
    this.imageAlignment = Alignment.center,
  });

  final String image;
  final String badge;
  final StatusBadgeType badgeType;
  final String title;
  final String subtitle;
  final Alignment imageAlignment;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 560;
    final desktop = MediaQuery.sizeOf(context).width >= 980;

    return Container(
      height: compact ? 330 : 300,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 28 : 32),
        image: DecorationImage(
          image: AssetImage(image),
          fit: BoxFit.cover,
          alignment: imageAlignment,
        ),
        boxShadow: AppColors.premiumShadow(opacity: .28),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(compact ? 28 : 32),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.brandBlue.withValues(alpha: .82),
              AppColors.deepPurple.withValues(alpha: .60),
              Colors.transparent,
            ],
            stops: const [0, .46, 1],
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(compact ? 20 : 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (!desktop) const _MobileMenuButton(onPhoto: true),
                      if (!desktop) const SizedBox(width: 8),
                      StatusBadge(text: badge, type: badgeType),
                      const Spacer(),
                      if (!desktop)
                        const _NotificationButton(onPhoto: true),
                    ],
                  ),
                  const Spacer(),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: compact ? double.infinity : 660,
                    ),
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headingLarge.copyWith(
                        color: Colors.white,
                        height: 1.08,
                        fontSize: compact ? 34 : 42,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: Colors.white.withValues(alpha: .94),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlainTopControls extends StatelessWidget {
  const _PlainTopControls({
    required this.badgeText,
    required this.badgeType,
  });

  final String badgeText;
  final StatusBadgeType badgeType;

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 980;

    return Row(
      children: [
        if (!desktop) const _MobileMenuButton(),
        const Spacer(),
        StatusBadge(text: badgeText, type: badgeType),
        if (!desktop) ...[
          const SizedBox(width: 8),
          const _NotificationButton(),
        ],
      ],
    );
  }
}

class _MobileMenuButton extends StatelessWidget {
  const _MobileMenuButton({this.onPhoto = false});

  final bool onPhoto;

  @override
  Widget build(BuildContext context) {
    return _CircleActionButton(
      icon: Icons.menu_rounded,
      onPhoto: onPhoto,
      onPressed: () => Scaffold.of(context).openDrawer(),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({this.onPhoto = false});

  final bool onPhoto;

  @override
  Widget build(BuildContext context) {
    return _CircleActionButton(
      icon: Icons.notifications_none_rounded,
      onPhoto: onPhoto,
      onPressed: () => Navigator.pushNamed(
        context,
        AppConstants.notificationsRoute,
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.onPressed,
    required this.onPhoto,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool onPhoto;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onPhoto
          ? Colors.white.withValues(alpha: .18)
          : AppColors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: onPhoto
                  ? Colors.white.withValues(alpha: .35)
                  : AppColors.borderColor,
            ),
          ),
          child: Icon(
            icon,
            color: onPhoto ? Colors.white : AppColors.deepPurple,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _ProfessionalSessionCard extends StatelessWidget {
  const _ProfessionalSessionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GradientIconBox(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.headingSmall),
                const SizedBox(height: 6),
                Text(subtitle, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationHintCard extends StatelessWidget {
  const _NotificationHintCard({
    required this.text,
    this.icon = Icons.notifications_rounded,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF7F8FF), Color(0xFFF8F2FF)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4DCFF)),
      ),
      child: Row(
        children: [
          _SoftIconCircle(icon: icon),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.rawStatus,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String rawStatus;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final type = badgeTypeFromStatus(rawStatus);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _SoftIconCircle(icon: icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.labelBold),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(subtitle!, style: AppTextStyles.captionText),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        StatusBadge(text: value, type: type),
      ],
    );
  }
}

class _SimpleDetailRow extends StatelessWidget {
  const _SimpleDetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(label, style: AppTextStyles.bodyMedium),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.labelBold.copyWith(
                    color: valueColor ?? AppColors.primaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              _SoftIconCircle(icon: icon, size: 34),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.labelBold.copyWith(
                    color: valueColor ?? AppColors.primaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

class _SoftIconCircle extends StatelessWidget {
  const _SoftIconCircle({required this.icon, this.size = 42});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.lightPurpleBackground,
      ),
      child: Icon(
        icon,
        color: AppColors.deepPurple,
        size: size * .48,
      ),
    );
  }
}

class _GradientIconBox extends StatelessWidget {
  const _GradientIconBox({required this.icon, this.size = 56});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.premiumShadow(opacity: .18),
      ),
      child: Icon(icon, color: Colors.white, size: size * .46),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: AppColors.premiumShadow(
          opacity: .15,
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ),
      child: child,
    );
  }
}

class _ElegantConfettiPainter extends CustomPainter {
  _ElegantConfettiPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(11);
    final colors = [
      AppColors.primaryPurple,
      AppColors.secondaryPurple,
      AppColors.successGreen,
      AppColors.gold,
    ];

    for (var i = 0; i < 34; i++) {
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: .45)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      final x = random.nextDouble() * size.width;
      final y = (random.nextDouble() * size.height * .36 +
          progress * size.height * .50) %
          size.height;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(random.nextDouble() * math.pi);
      canvas.drawLine(
        Offset.zero,
        Offset(7 + random.nextDouble() * 8, 0),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ElegantConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

String _text(
    Map<String, dynamic> data,
    String key, [
      String fallback = '',
    ]) {
  final value = data[key];
  if (value == null) return fallback;
  final text = value.toString();
  return text.trim().isEmpty ? fallback : text;
}

String _friendlyStatus(dynamic value) {
  final raw = value?.toString().trim().toLowerCase() ?? '';
  if (raw.isEmpty || raw == 'not submitted') return 'Not submitted';
  if (raw == 'approved' || raw == 'verified') return 'Verified';
  if (raw == 'paid') return 'Paid';
  if (raw == 'submitted') return 'Submitted';
  if (raw == 'rejected') return 'Rejected';
  if (raw == 'pending') return 'Pending';
  if (raw == 'in progress' || raw == 'in_progress') return 'In progress';

  return raw
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _maskCnic(String cnic) {
  final digits = cnic.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length != 13) return cnic;
  return '${digits.substring(0, 5)}-XXXXXXX-${digits.substring(12)}';
}
