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
import '../utils/app_text_styles.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/header_actions.dart';
import '../widgets/status_badge.dart';

class BallotingScreen extends StatefulWidget {
  const BallotingScreen({super.key});

  @override
  State<BallotingScreen> createState() => _BallotingScreenState();
}

class _BallotingScreenState extends State<BallotingScreen> with TickerProviderStateMixin {
  final _firestoreService = FirestoreService();
  late final AnimationController _pulse;
  late final AnimationController _confetti;
  Timer? _timer;
  DateTime? _drawDate;
  Duration _remaining = Duration.zero;
  ResultModel? _result;
  bool _resultLoading = true;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200), lowerBound: .94, upperBound: 1.03)..repeat(reverse: true);
    _confetti = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
    _loadResult();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _loadResult() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await _firestoreService.getResultForApplicant(uid);
      if (mounted) setState(() => _result = doc == null ? null : ResultModel.fromFirestore(doc));
    } catch (_) {
      // Result stays empty until published.
    } finally {
      if (mounted) setState(() => _resultLoading = false);
    }
  }

  void _startCountdown(DateTime? drawDate) {
    _timer?.cancel();
    _drawDate = drawDate;
    if (drawDate == null) {
      _remaining = Duration.zero;
      return;
    }
    _remaining = drawDate.difference(DateTime.now());
    if (_remaining.isNegative) _remaining = Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _drawDate == null) return;
      final diff = _drawDate!.difference(DateTime.now());
      setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
    });
  }

  DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('ballot_config').doc('main').snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final status = _normalizeStatus(data['status']?.toString() ?? 'upcoming');
        final drawDate = _date(data['drawDate']);
        if (status == 'upcoming') _startCountdown(drawDate);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Balloting'),
            actions: [
              Center(child: StatusBadge(text: _statusLabel(status), type: _badgeType(status))),
              const NotificationBell(),
              const SizedBox(width: 8),
            ],
          ),
          bottomNavigationBar: const AppBottomNavBar(currentIndex: 4),
          body: _resultLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
              : RefreshIndicator(
                  color: AppColors.primaryPurple,
                  onRefresh: _loadResult,
                  child: ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        child: _stateWidget(status, data, drawDate),
                      ),
                      const SizedBox(height: 18),
                      if (status == 'live') const _LiveResultsPanel(),
                      if (status != 'live') _OfficialNote(status: status),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _stateWidget(String status, Map<String, dynamic> data, DateTime? drawDate) {
    switch (status) {
      case 'live':
        return _LiveState(key: const ValueKey('live'), data: data);
      case 'winner':
        return _WinnerState(key: const ValueKey('winner'), data: data, result: _result, confetti: _confetti);
      case 'notselected':
        return _NotSelectedState(key: const ValueKey('notselected'), data: data, result: _result);
      case 'completed':
        return _CompletedState(key: const ValueKey('completed'), data: data, result: _result);
      case 'upcoming':
      default:
        return _UpcomingState(key: const ValueKey('upcoming'), data: data, drawDate: drawDate, remaining: _remaining, pulse: _pulse);
    }
  }

  String _normalizeStatus(String value) => value.toLowerCase().replaceAll('_', '').replaceAll('-', '').trim();
  String _statusLabel(String status) {
    if (status == 'live') return 'LIVE';
    if (status == 'winner') return 'SELECTED';
    if (status == 'notselected') return 'RESULT';
    if (status == 'completed') return 'COMPLETED';
    return 'UPCOMING';
  }

  StatusBadgeType _badgeType(String status) {
    if (status == 'winner' || status == 'completed' || status == 'live') return StatusBadgeType.success;
    if (status == 'notselected') return StatusBadgeType.error;
    return StatusBadgeType.warning;
  }
}

class _UpcomingState extends StatelessWidget {
  const _UpcomingState({super.key, required this.data, required this.drawDate, required this.remaining, required this.pulse});
  final Map<String, dynamic> data;
  final DateTime? drawDate;
  final Duration remaining;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final project = _text(data, 'projectName', 'Official Housing Balloting');
    final block = _text(data, 'block', 'Block');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _PhotoHeader(
        image: AppAssets.courtyardBackground,
        badge: 'UPCOMING BALLOTING',
        title: '$project - $block',
        subtitle: drawDate == null ? 'Draw date will be announced by society administration.' : DateFormat('EEEE, d MMMM yyyy • hh:mm a').format(drawDate!),
      ),
      const SizedBox(height: 18),
      _CountdownCard(remaining: remaining),
      const SizedBox(height: 18),
      ScaleTransition(
        scale: pulse,
        child: const _ProfessionalSessionCard(
          title: 'Official draw is being prepared',
          subtitle: 'Only verified applications will be included in the balloting session.',
          icon: Icons.event_available_rounded,
        ),
      ),
      const SizedBox(height: 18),
      _InfoPanel(
        title: 'Before the Draw',
        rows: {
          'Application': 'Submitted and verified',
          'Documents': 'Submitted for review',
          'Payment': 'Submitted / verified',
        },
      ),
    ]);
  }
}

class _LiveState extends StatelessWidget {
  const _LiveState({super.key, required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final project = _text(data, 'projectName', 'Official Housing Balloting');
    final block = _text(data, 'block', 'Block');
    final current = _text(data, 'currentNumber', '----');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _PhotoHeader(
        image: AppAssets.heroBackground,
        badge: 'LIVE NOW',
        title: 'Live Balloting Session',
        subtitle: '$project - $block',
      ),
      const SizedBox(height: 18),
      _LiveSessionCard(data: data),
      const SizedBox(height: 18),
      _DrawNumberCard(title: 'Current Draw Number', number: current),
      const SizedBox(height: 18),
      _LiveFeedCard(feed: data['liveFeed']),
    ]);
  }
}

class _WinnerState extends StatelessWidget {
  const _WinnerState({super.key, required this.data, required this.result, required this.confetti});
  final Map<String, dynamic> data;
  final ResultModel? result;
  final Animation<double> confetti;

  @override
  Widget build(BuildContext context) {
    final number = result?.plotNumber ?? _text(data, 'selectedPlotNumber', '');
    final applicationNo = result?.serialNumber ?? _text(data, 'selectedApplicationId', '');
    final block = result?.plotLocation ?? _text(data, 'block', '-');
    return Stack(children: [
      Positioned.fill(child: AnimatedBuilder(animation: confetti, builder: (_, __) => CustomPaint(painter: _ElegantConfettiPainter(confetti.value)))),
      Column(children: [
        const SizedBox(height: 8),
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.successGreen, boxShadow: [BoxShadow(color: AppColors.successGreen.withValues(alpha: .35), blurRadius: 36, offset: const Offset(0, 14))]),
          child: const Icon(Icons.verified_rounded, color: AppColors.white, size: 52),
        ),
        const SizedBox(height: 18),
        Text('Congratulations!', style: AppTextStyles.headingSmall.copyWith(color: AppColors.primaryText)),
        const SizedBox(height: 4),
        Text('You Won', style: AppTextStyles.headingLarge.copyWith(color: AppColors.deepPurple, fontSize: 36)),
        const SizedBox(height: 8),
        Text('Your application has been selected in the official balloting.', textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
        const SizedBox(height: 20),
        _InfoPanel(title: 'Selection Details', rows: {
          'Application No.': applicationNo.isEmpty ? '-' : applicationNo,
          'Block': block,
          'Plot Number': number.isEmpty ? '-' : number,
          'Status': 'Selected',
        }),
        const SizedBox(height: 18),
        const _ProfessionalSessionCard(title: 'Next Step', subtitle: 'Society administration will contact selected applicants for further processing.', icon: Icons.handshake_rounded),
      ]),
    ]);
  }
}

class _NotSelectedState extends StatelessWidget {
  const _NotSelectedState({super.key, required this.data, required this.result});
  final Map<String, dynamic> data;
  final ResultModel? result;

  @override
  Widget build(BuildContext context) {
    final applicationNo = result?.serialNumber ?? _text(data, 'applicationNumber', '');
    final block = result?.plotLocation ?? _text(data, 'block', '-');
    final drawn = _text(data, 'drawnNumber', result?.serialNumber ?? '-');
    return Column(children: [
      const SizedBox(height: 10),
      Container(width: 88, height: 88, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.lightPurpleBackground), child: const Icon(Icons.close_rounded, color: AppColors.deepPurple, size: 48)),
      const SizedBox(height: 16),
      Text('Not Selected', style: AppTextStyles.headingLarge.copyWith(color: AppColors.errorRed)),
      const SizedBox(height: 6),
      Text('Thank you for participating in the official balloting.', textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
      const SizedBox(height: 22),
      _InfoPanel(title: 'Draw Details', rows: {
        'Application No.': applicationNo.isEmpty ? '-' : applicationNo,
        'Block': block,
        'Draw Number': drawn,
        'Status': 'Not Selected',
      }),
      const SizedBox(height: 18),
      const _ProfessionalSessionCard(title: 'Stay Connected', subtitle: 'Future projects and scheme updates will appear in notifications.', icon: Icons.notifications_active_rounded),
    ]);
  }
}

class _CompletedState extends StatelessWidget {
  const _CompletedState({super.key, required this.data, required this.result});
  final Map<String, dynamic> data;
  final ResultModel? result;

  @override
  Widget build(BuildContext context) {
    final project = _text(data, 'projectName', 'Official Housing Balloting');
    final block = _text(data, 'block', '-');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _PhotoHeader(image: AppAssets.heroBackground, badge: 'COMPLETED', title: 'Balloting Completed', subtitle: '$project - $block'),
      const SizedBox(height: 18),
      _InfoPanel(title: 'Draw Summary', rows: {
        'Block': block,
        'Eligible Applications': _text(data, 'totalEligibleApplications', _text(data, 'totalApplicants', '0')),
        'Total Plots': _text(data, 'totalPlots', '0'),
        'Selected': _text(data, 'selectedApplications', _text(data, 'totalWinners', '0')),
        'Not Selected': _text(data, 'notSelectedApplications', '0'),
        'Your Result': result == null ? 'Pending publication' : result!.isSelected ? 'Selected' : 'Not selected',
      }),
      const SizedBox(height: 18),
      _TimelinePanel(timeline: data['timeline']),
    ]);
  }
}

class _LiveResultsPanel extends StatelessWidget {
  const _LiveResultsPanel();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('ballot_live_results').snapshots(),
      builder: (context, snapshot) {
        final docs = [...?snapshot.data?.docs];
        docs.sort((a, b) {
          final ad = (a.data() as Map<String, dynamic>)['createdAt'];
          final bd = (b.data() as Map<String, dynamic>)['createdAt'];
          final at = ad is Timestamp ? ad.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
          final bt = bd is Timestamp ? bd.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
          return bt.compareTo(at);
        });
        return _Card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Live Results', style: AppTextStyles.headingSmall),
              const SizedBox(width: 8),
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.errorRed, shape: BoxShape.circle)),
            ]),
            const SizedBox(height: 14),
            if (docs.isEmpty)
              Text('Live result entries will appear here when published by administration.', style: AppTextStyles.bodyMedium)
            else
              ...docs.take(12).map((doc) {
                final row = doc.data() as Map<String, dynamic>? ?? {};
                return _LiveResultTile(
                  applicationNo: _text(row, 'applicationNumber', _text(row, 'applicationNo', '-')),
                  cnic: _maskCnic(_text(row, 'cnic', '-')),
                  plot: _text(row, 'plotNumber', '-'),
                );
              }),
          ]),
        );
      },
    );
  }
}

class _LiveResultTile extends StatelessWidget {
  const _LiveResultTile({required this.applicationNo, required this.cnic, required this.plot});
  final String applicationNo;
  final String cnic;
  final String plot;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.pageBackground, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        const CircleAvatar(radius: 18, backgroundColor: AppColors.lightPurpleBackground, child: Icon(Icons.home_work_rounded, color: AppColors.deepPurple, size: 18)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(applicationNo, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.labelBold),
          const SizedBox(height: 2),
          Text(cnic, style: AppTextStyles.captionText),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.successLightBackground, borderRadius: BorderRadius.circular(100)), child: Text(plot, style: AppTextStyles.captionText.copyWith(color: AppColors.successGreen, fontWeight: FontWeight.w900))),
      ]),
    );
  }
}

class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({required this.image, required this.badge, required this.title, required this.subtitle});
  final String image;
  final String badge;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), image: DecorationImage(image: AssetImage(image), fit: BoxFit.cover), boxShadow: AppColors.premiumShadow()),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.deepPurple.withValues(alpha: .68), AppColors.primaryPurple.withValues(alpha: .38), AppColors.darkNavy.withValues(alpha: .28)])),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          StatusBadge(text: badge, type: badge == 'LIVE NOW' || badge == 'COMPLETED' ? StatusBadgeType.success : StatusBadgeType.warning),
          const Spacer(),
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.headingLarge.copyWith(color: AppColors.white, height: 1.12)),
          const SizedBox(height: 8),
          Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white.withValues(alpha: .88), fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _CountdownCard extends StatelessWidget {
  const _CountdownCard({required this.remaining});
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final values = [
      (remaining.inDays, 'Days'),
      (remaining.inHours.remainder(24), 'Hours'),
      (remaining.inMinutes.remainder(60), 'Minutes'),
      (remaining.inSeconds.remainder(60), 'Seconds'),
    ];
    return _Card(child: Row(children: values.map((e) => Expanded(child: Column(children: [Text(e.$1.toString().padLeft(2, '0'), style: AppTextStyles.headingMedium.copyWith(color: AppColors.deepPurple)), const SizedBox(height: 4), Text(e.$2, style: AppTextStyles.captionText)]))).toList()));
  }
}

class _LiveSessionCard extends StatelessWidget {
  const _LiveSessionCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 54, height: 54, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.video_camera_front_rounded, color: AppColors.white)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Live Balloting Session', style: AppTextStyles.headingSmall),
            const SizedBox(height: 4),
            Text(_text(data, 'message', 'Official draw is currently in progress.'), style: AppTextStyles.bodyMedium),
          ])),
        ]),
        const SizedBox(height: 16),
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), image: const DecorationImage(image: AssetImage(AppAssets.courtyardBackground), fit: BoxFit.cover)),
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: AppColors.darkNavy.withValues(alpha: .40)),
            child: Center(child: Text('OFFICIAL LIVE DRAW', style: AppTextStyles.headingSmall.copyWith(color: AppColors.white, letterSpacing: 1.2))),
          ),
        ),
      ]),
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
    final digits = clean.isEmpty ? ['-', '-', '-', '-'] : clean.padLeft(4, '0').split('').take(6).toList();
    return _Card(child: Column(children: [
      Text(title, style: AppTextStyles.labelBold),
      const SizedBox(height: 14),
      Row(children: digits.map((d) => Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: AppColors.lightPurpleBackground, borderRadius: BorderRadius.circular(16)), child: Text(d, textAlign: TextAlign.center, style: AppTextStyles.headingMedium.copyWith(color: AppColors.deepPurple))))).toList()),
    ]));
  }
}

class _LiveFeedCard extends StatelessWidget {
  const _LiveFeedCard({required this.feed});
  final dynamic feed;

  @override
  Widget build(BuildContext context) {
    final items = feed is List ? feed : const [];
    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Official Live Feed', style: AppTextStyles.headingSmall),
      const SizedBox(height: 12),
      if (items.isEmpty)
        Text('Live updates will appear here during the official draw.', style: AppTextStyles.bodyMedium)
      else
        ...items.take(6).map((item) {
          final map = item is Map ? item : {};
          return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text((map['time'] ?? '').toString(), style: AppTextStyles.captionText),
            const SizedBox(width: 12),
            Expanded(child: Text((map['text'] ?? '').toString(), style: AppTextStyles.labelBold)),
          ]));
        }),
    ]));
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.title, required this.rows});
  final String title;
  final Map<String, String> rows;

  @override
  Widget build(BuildContext context) {
    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppTextStyles.headingSmall),
      const SizedBox(height: 14),
      ...rows.entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 128, child: Text(e.key, style: AppTextStyles.captionText)),
        Expanded(child: Text(e.value.isEmpty ? '-' : e.value, textAlign: TextAlign.right, style: AppTextStyles.labelBold)),
      ]))),
    ]));
  }
}

class _TimelinePanel extends StatelessWidget {
  const _TimelinePanel({required this.timeline});
  final dynamic timeline;

  @override
  Widget build(BuildContext context) {
    final items = timeline is List ? timeline : const [];
    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Timeline', style: AppTextStyles.headingSmall),
      const SizedBox(height: 14),
      if (items.isEmpty)
        Text('Timeline will appear when published by administration.', style: AppTextStyles.bodyMedium)
      else
        ...items.map((item) {
          final map = item is Map ? item : {};
          return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text((map['title'] ?? '').toString(), style: AppTextStyles.labelBold)),
            Text((map['date'] ?? '').toString(), style: AppTextStyles.captionText),
          ]));
        }),
    ]));
  }
}

class _ProfessionalSessionCard extends StatelessWidget {
  const _ProfessionalSessionCard({required this.title, required this.subtitle, required this.icon});
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _Card(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 52, height: 52, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: AppColors.white)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: AppTextStyles.headingSmall), const SizedBox(height: 6), Text(subtitle, style: AppTextStyles.bodyMedium)])),
    ]));
  }
}

class _OfficialNote extends StatelessWidget {
  const _OfficialNote({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.borderColor)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.verified_user_rounded, color: AppColors.deepPurple),
        const SizedBox(width: 12),
        Expanded(child: Text('All balloting information is displayed from official Firestore records published by society administration.', style: AppTextStyles.bodyMedium)),
      ]),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderColor), boxShadow: AppColors.premiumShadow(opacity: .22)), child: child);
  }
}

class _ElegantConfettiPainter extends CustomPainter {
  _ElegantConfettiPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(11);
    final colors = [AppColors.primaryPurple, AppColors.secondaryPurple, AppColors.successGreen, AppColors.gold];
    for (var i = 0; i < 36; i++) {
      final paint = Paint()..color = colors[i % colors.length].withValues(alpha: .45)..strokeWidth = 3..strokeCap = StrokeCap.round;
      final x = random.nextDouble() * size.width;
      final y = (random.nextDouble() * size.height * .45 + progress * size.height * .55) % size.height;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(random.nextDouble() * math.pi);
      canvas.drawLine(Offset.zero, Offset(8 + random.nextDouble() * 8, 0), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ElegantConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}

String _text(Map<String, dynamic> data, String key, [String fallback = '']) {
  final value = data[key];
  if (value == null) return fallback;
  final text = value.toString();
  return text.trim().isEmpty ? fallback : text;
}

String _maskCnic(String cnic) {
  final digits = cnic.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length != 13) return cnic;
  return '${digits.substring(0, 5)}-XXXXXXX-${digits.substring(12)}';
}
