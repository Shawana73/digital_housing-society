import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/applicant_model.dart';
import '../models/application_model.dart';
import '../models/notification_model.dart';
import '../models/payment_model.dart';
import '../models/plot_model.dart';
import '../providers/applicant_provider.dart';
import '../services/firestore_service.dart';
import '../utils/app_assets.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/demo_data.dart';
import '../widgets/responsive_shell.dart';

/// Stable dashboard implementation.
///
/// Important runtime choices:
/// - no LayoutBuilder
/// - no FutureBuilder
/// - no StreamBuilder in the primary layout tree
/// - no AnimatedContainer
/// - Firestore loads happen after first paint and are guarded with fallbacks
///
/// This keeps navigation responsive even while Firebase is loading or offline.
class ApplicantDashboardScreen extends StatefulWidget {
  const ApplicantDashboardScreen({super.key});

  @override
  State<ApplicantDashboardScreen> createState() =>
      _ApplicantDashboardScreenState();
}

class _ApplicantDashboardScreenState extends State<ApplicantDashboardScreen> {
  final FirestoreService _service = FirestoreService();

  bool _uploadExists = false;
  bool _resultExists = false;
  bool _supplementalLoading = false;
  PlotModel? _featuredPlot;
  List<NotificationModel> _recentNotifications = const [];

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadDashboardData());
    });
  }

  Future<void> _loadDashboardData() async {
    final uid = _uid;
    if (uid == null || !mounted) return;

    if (mounted) {
      setState(() => _supplementalLoading = true);
    }

    // These four operations start together. A slow optional Firestore query
    // can no longer keep the dashboard blank or block sidebar navigation.
    await Future.wait<void>([
      _loadProviderData(uid),
      _loadJourneyFlags(uid),
      _loadFeaturedPlot(),
      _loadRecentNotifications(uid),
    ]);

    if (mounted) {
      setState(() => _supplementalLoading = false);
    }
  }

  Future<void> _loadProviderData(String uid) async {
    try {
      await context.read<ApplicantProvider>().loadAll(uid);
    } catch (_) {
      // ApplicantProvider already exposes a friendly error state.
    }
  }

  Future<void> _loadJourneyFlags(String uid) async {
    try {
      final uploadFuture = _service.getUpload(uid);
      final resultFuture = _service.getResultForApplicant(uid);

      final upload = await uploadFuture;
      final result = await resultFuture;

      if (!mounted) return;
      setState(() {
        _uploadExists = upload != null;
        _resultExists = result != null;
      });
    } catch (_) {
      // Keep safe default values while offline / permission checks settle.
    }
  }

  Future<void> _loadFeaturedPlot() async {
    try {
      final snapshot = await _service
          .getPlots()
          .first
          .timeout(const Duration(seconds: 5));

      PlotModel? plot;
      for (final doc in snapshot.docs) {
        try {
          final candidate = PlotModel.fromFirestore(doc);
          if (candidate.featured) {
            plot = candidate;
            break;
          }
          plot ??= candidate;
        } catch (_) {
          // Ignore a malformed admin record instead of breaking Dashboard.
        }
      }

      if (!mounted) return;
      setState(() => _featuredPlot = plot);
    } catch (_) {
      // Local professional preview remains visible until admin data arrives.
    }
  }

  Future<void> _loadRecentNotifications(String uid) async {
    try {
      final snapshot = await _service
          .getNotifications(uid)
          .first
          .timeout(const Duration(seconds: 5));

      final parsed = <NotificationModel>[];
      for (final doc in snapshot.docs) {
        try {
          parsed.add(NotificationModel.fromFirestore(doc));
        } catch (_) {
          // One malformed notification must never blank the whole dashboard.
        }
      }
      parsed.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!mounted) return;
      setState(() => _recentNotifications = parsed.take(4).toList());
    } catch (_) {
      // Empty state is already rendered.
    }
  }

  Future<void> _refresh() => _loadDashboardData();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApplicantProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 700;
    final wide = width >= 1280;

    return DhsResponsiveShell(
      currentRoute: AppConstants.dashboardRoute,
      mobileTitle: 'Dashboard',
      child: RefreshIndicator(
        color: AppColors.primaryPurple,
        onRefresh: _refresh,
        child: ListView(
          key: const PageStorageKey<String>('dashboard-list'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            width >= 980 ? 24 : 14,
            18,
            width >= 980 ? 24 : 14,
            28,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1320),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_supplementalLoading || provider.isLoading)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: LinearProgressIndicator(
                          minHeight: 2,
                          color: AppColors.primaryPurple,
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    if (!compact)
                      _DesktopGreeting(applicant: provider.currentApplicant),
                    if (!compact) const SizedBox(height: 14),
                    _DashboardHero(
                      applicant: provider.currentApplicant,
                      application: provider.currentApplication,
                      payment: provider.currentPayment,
                      uploadExists: _uploadExists,
                      resultExists: _resultExists,
                      compact: compact,
                    ),
                    const SizedBox(height: 16),
                    _StatusSection(
                      application: provider.currentApplication,
                      payment: provider.currentPayment,
                      uploadExists: _uploadExists,
                      resultExists: _resultExists,
                      compact: compact,
                      wide: wide,
                    ),
                    const SizedBox(height: 16),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(flex: 11, child: _QuickActionsPanel()),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 9,
                            child: _FeaturedPlotPanel(plot: _displayPlot),
                          ),
                        ],
                      )
                    else ...[
                      const _QuickActionsPanel(),
                      const SizedBox(height: 16),
                      _FeaturedPlotPanel(plot: _displayPlot),
                    ],
                    const SizedBox(height: 16),
                    _RecentUpdatesPanel(
                      notifications: _recentNotifications,
                    ),
                    const SizedBox(height: 18),
                    if (provider.error != null)
                      _SoftMessage(text: provider.error!),
                    if (provider.error != null) const SizedBox(height: 12),
                    const _DashboardFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PlotModel get _displayPlot {
    if (_featuredPlot != null) return _featuredPlot!;
    for (final plot in DemoData.plotModels) {
      if (plot.featured) return plot;
    }
    return DemoData.plotModels.first;
  }
}

class _DesktopGreeting extends StatelessWidget {
  const _DesktopGreeting({required this.applicant});

  final ApplicantModel? applicant;

  @override
  Widget build(BuildContext context) {
    final name = _displayName(applicant);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good day, ${name.split(' ').first} 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Track your application, payments, plots and latest DHS activity.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: () => Navigator.pushNamed(
            context,
            AppConstants.notificationsRoute,
          ),
          icon: const Badge(
            smallSize: 8,
            backgroundColor: AppColors.errorRed,
            child: Icon(Icons.notifications_none_rounded),
          ),
        ),
        const SizedBox(width: 10),
        CircleAvatar(
          radius: 19,
          backgroundColor: AppColors.deepPurple,
          child: Text(
            _initials(name),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.applicant,
    required this.application,
    required this.payment,
    required this.uploadExists,
    required this.resultExists,
    required this.compact,
  });

  final ApplicantModel? applicant;
  final ApplicationModel? application;
  final PaymentModel? payment;
  final bool uploadExists;
  final bool resultExists;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final name = _displayName(applicant);
    final step = _currentJourneyStep(
      application: application,
      payment: payment,
      uploadExists: uploadExists,
      resultExists: resultExists,
    );

    return SizedBox(
      height: compact ? 455 : 380,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              AppAssets.courtyardBackground,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0xFF355FD9),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xE82F5FDE),
                    Color(0xE65B2EEA),
                    Color(0xB77C4DFF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              left: compact ? 20 : 30,
              right: compact ? 20 : 30,
              top: compact ? 20 : 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HeroPill(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Welcome Back',
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Hello, $name 👋',
                    maxLines: compact ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 29 : 40,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your journey to your dream home is in progress.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFFF5F3FF),
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppConstants.applicationRoute,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: .16),
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: .32),
                          ),
                        ),
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text(
                          'View Application',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      _HeroPill(
                        icon: Icons.calendar_month_rounded,
                        label: DateFormat('EEE, d MMM yyyy').format(DateTime.now()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              left: compact ? 14 : 22,
              right: compact ? 14 : 22,
              bottom: compact ? 16 : 20,
              child: _JourneyStrip(currentStep: step, compact: compact),
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyStrip extends StatelessWidget {
  const _JourneyStrip({required this.currentStep, required this.compact});

  final int currentStep;
  final bool compact;

  static const labels = ['Submitted', 'Documents', 'Under Review', 'Balloting'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 130 : 114,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF14225A).withValues(alpha: .66),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .18)),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          return Expanded(
            child: _JourneyStage(
              number: index + 1,
              label: labels[index],
              completed: index < currentStep,
              active: index == currentStep,
              compact: compact,
            ),
          );
        }),
      ),
    );
  }
}

class _JourneyStage extends StatelessWidget {
  const _JourneyStage({
    required this.number,
    required this.label,
    required this.completed,
    required this.active,
    required this.compact,
  });

  final int number;
  final String label;
  final bool completed;
  final bool active;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final highlighted = completed || active;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: compact ? 34 : 40,
          height: compact ? 34 : 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: highlighted
                ? const LinearGradient(
                    colors: [Color(0xFF6847E8), Color(0xFF9A50F1)],
                  )
                : null,
            color: highlighted ? null : Colors.white.withValues(alpha: .13),
            border: Border.all(
              color: active ? Colors.white : Colors.white.withValues(alpha: .30),
              width: active ? 2 : 1,
            ),
          ),
          child: completed
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 19)
              : Text(
                  '$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 9 : 11,
            height: 1.05,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({
    required this.application,
    required this.payment,
    required this.uploadExists,
    required this.resultExists,
    required this.compact,
    required this.wide,
  });

  final ApplicationModel? application;
  final PaymentModel? payment;
  final bool uploadExists;
  final bool resultExists;
  final bool compact;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final items = <_StatusData>[
      _StatusData(
        icon: Icons.description_outlined,
        title: 'Application',
        value: application?.status ?? 'Not submitted',
        tone: _tone(application?.status),
      ),
      _StatusData(
        icon: Icons.folder_copy_outlined,
        title: 'Documents',
        value: uploadExists ? 'Submitted' : 'Not submitted',
        tone: uploadExists ? _StatusTone.success : _StatusTone.info,
      ),
      _StatusData(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Payment',
        value: payment?.status ?? 'Not submitted',
        tone: _tone(payment?.status),
      ),
      _StatusData(
        icon: Icons.emoji_events_outlined,
        title: 'Result',
        value: resultExists ? 'Available' : 'Not available',
        tone: resultExists ? _StatusTone.success : _StatusTone.info,
      ),
    ];

    if (wide) {
      return Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(child: _StatusCard(data: items[i], compact: compact)),
            if (i != items.length - 1) const SizedBox(width: 12),
          ],
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatusCard(data: items[0], compact: compact)),
            const SizedBox(width: 10),
            Expanded(child: _StatusCard(data: items[1], compact: compact)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _StatusCard(data: items[2], compact: compact)),
            const SizedBox(width: 10),
            Expanded(child: _StatusCard(data: items[3], compact: compact)),
          ],
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.data, required this.compact});

  final _StatusData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = _toneColors(data.tone);
    return Container(
      height: compact ? 105 : 112,
      padding: EdgeInsets.all(compact ? 11 : 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFE6E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 37 : 44,
            height: compact ? 37 : 44,
            decoration: BoxDecoration(
              color: colors.$2,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(data.icon, color: colors.$1, size: compact ? 19 : 22),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: compact ? 10.5 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _titleCase(data.value),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.$1,
                    fontSize: compact ? 12.5 : 15,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel();

  static const actions = <_ActionData>[
    _ActionData(
      label: 'Upload Documents',
      subtitle: 'Upload or manage application documents',
      icon: Icons.cloud_upload_outlined,
      route: AppConstants.uploadRoute,
      featured: true,
    ),
    _ActionData(
      label: 'Make Payment',
      subtitle: 'Secure test-mode application payment',
      icon: Icons.account_balance_wallet_outlined,
      route: AppConstants.paymentRoute,
    ),
    _ActionData(
      label: 'Balloting',
      subtitle: 'Check registration and ballot status',
      icon: Icons.casino_outlined,
      route: AppConstants.ballotingRoute,
    ),
    _ActionData(
      label: 'Explore Plots',
      subtitle: 'Browse available DHS plots',
      icon: Icons.travel_explore_rounded,
      route: AppConstants.plotsRoute,
      featured: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Quick Actions'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _ActionTile(data: actions[0])),
              const SizedBox(width: 10),
              Expanded(child: _ActionTile(data: actions[1])),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _ActionTile(data: actions[2])),
              const SizedBox(width: 10),
              Expanded(child: _ActionTile(data: actions[3])),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.data});

  final _ActionData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, data.route),
        borderRadius: BorderRadius.circular(19),
        child: Ink(
          height: 136,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            gradient: data.featured
                ? const LinearGradient(
                    colors: [Color(0xFF5A41E6), Color(0xFF8A4AEC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFFF5F2FF), Color(0xFFEEF5FF)],
                  ),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: const Color(0xFFE2E3F1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                data.icon,
                color: data.featured ? Colors.white : AppColors.deepPurple,
              ),
              const SizedBox(height: 12),
              Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: data.featured ? Colors.white : AppColors.primaryText,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: data.featured
                      ? Colors.white.withValues(alpha: .82)
                      : AppColors.secondaryText,
                  fontSize: 10.5,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedPlotPanel extends StatelessWidget {
  const _FeaturedPlotPanel({required this.plot});

  final PlotModel plot;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Featured Plot'),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 2.2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: plot.imageUrl.trim().isNotEmpty
                  ? Image.network(
                      plot.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        AppAssets.heroBackground,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      AppAssets.heroBackground,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Color(0xFFEDE7FF),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Plot # ${plot.plotNumber}${plot.block.isEmpty ? '' : ', Block ${plot.block}'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 11,
            runSpacing: 7,
            children: [
              _MiniFact(icon: Icons.crop_square_rounded, text: plot.size),
              _MiniFact(icon: Icons.park_outlined, text: plot.facing),
              _MiniFact(icon: Icons.add_road_rounded, text: plot.roadWidth),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  plot.price > 0
                      ? NumberFormat.currency(
                          locale: 'en_PK',
                          symbol: 'PKR ',
                          decimalDigits: 0,
                        ).format(plot.price)
                      : 'Price on request',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.deepPurple,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppConstants.mapRoute,
                ),
                child: const Text('View Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentUpdatesPanel extends StatelessWidget {
  const _RecentUpdatesPanel({required this.notifications});

  final List<NotificationModel> notifications;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Recent Updates',
            trailing: TextButton(
              onPressed: () => Navigator.pushNamed(
                context,
                AppConstants.notificationsRoute,
              ),
              child: const Text('View All'),
            ),
          ),
          if (notifications.isEmpty)
            const _EmptyMessage(text: 'No DHS updates yet.')
          else
            ...notifications.map(
              (item) => _NotificationRow(notification: item),
            ),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification});

  final NotificationModel notification;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final route = notification.actionRoute.trim();
        if (route.isNotEmpty) Navigator.pushNamed(context, route);
      },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF0ECFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.deepPurple,
                size: 20,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${notification.message} • ${_relativeDate(notification.createdAt)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 11.5,
                      height: 1.25,
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
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 285),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: .26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xFFE7E7F0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepPurple.withValues(alpha: .05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _MiniFact extends StatelessWidget {
  const _MiniFact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF69748C)),
        const SizedBox(width: 5),
        Text(
          text.trim().isEmpty ? 'Pending' : text,
          style: const TextStyle(
            color: AppColors.secondaryText,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.secondaryText),
        ),
      ),
    );
  }
}

class _SoftMessage extends StatelessWidget {
  const _SoftMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.warningOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardFooter extends StatelessWidget {
  const _DashboardFooter();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '© 2026 Digital Housing Society • Secure applicant portal',
      textAlign: TextAlign.center,
      style: TextStyle(color: AppColors.secondaryText, fontSize: 11),
    );
  }
}

class _StatusData {
  const _StatusData({
    required this.icon,
    required this.title,
    required this.value,
    required this.tone,
  });

  final IconData icon;
  final String title;
  final String value;
  final _StatusTone tone;
}

class _ActionData {
  const _ActionData({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.route,
    this.featured = false,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final String route;
  final bool featured;
}

enum _StatusTone { success, warning, danger, info }

_StatusTone _tone(String? value) {
  final text = (value ?? '').toLowerCase();
  if (text.contains('reject') || text.contains('not selected')) {
    return _StatusTone.danger;
  }
  if (text.contains('verified') ||
      text.contains('approved') ||
      text.contains('submitted') ||
      text == 'selected' ||
      text.contains('winner') ||
      text.contains('paid')) {
    return _StatusTone.success;
  }
  if (text.contains('pending') ||
      text.contains('review') ||
      text.contains('progress')) {
    return _StatusTone.warning;
  }
  return _StatusTone.info;
}

(Color, Color) _toneColors(_StatusTone tone) {
  switch (tone) {
    case _StatusTone.success:
      return (const Color(0xFF16A765), const Color(0xFFE9F9F0));
    case _StatusTone.warning:
      return (const Color(0xFFF59E0B), const Color(0xFFFFF6E4));
    case _StatusTone.danger:
      return (const Color(0xFFE5484D), const Color(0xFFFFEEEE));
    case _StatusTone.info:
      return (const Color(0xFF3B63E6), const Color(0xFFEEF3FF));
  }
}

int _currentJourneyStep({
  required ApplicationModel? application,
  required PaymentModel? payment,
  required bool uploadExists,
  required bool resultExists,
}) {
  if (application == null) return 0;
  if (!uploadExists) return 1;
  if (payment == null) return 2;
  if (resultExists) return 4;
  return 3;
}

String _displayName(ApplicantModel? applicant) {
  final text = applicant?.fullName.trim() ?? '';
  return text.isEmpty ? 'Applicant' : text;
}

String _initials(String name) {
  final parts = name
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList();
  if (parts.isEmpty) return 'A';
  return parts.map((part) => part[0].toUpperCase()).join();
}

String _titleCase(String value) {
  final text = value.trim();
  if (text.isEmpty) return 'Not Available';
  return text
      .split(RegExp(r'\s+'))
      .map((part) => part.isEmpty
          ? part
          : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _relativeDate(DateTime date) {
  final difference = DateTime.now().difference(date);
  if (difference.inMinutes < 1) return 'Now';
  if (difference.inHours < 1) return '${difference.inMinutes}m';
  if (difference.inDays < 1) return '${difference.inHours}h';
  if (difference.inDays < 7) return '${difference.inDays}d';
  return DateFormat('d MMM').format(date);
}
