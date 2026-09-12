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

class ApplicantDashboardScreen extends StatefulWidget {
  const ApplicantDashboardScreen({super.key});

  @override
  State<ApplicantDashboardScreen> createState() =>
      _ApplicantDashboardScreenState();
}

class _ApplicantDashboardScreenState
    extends State<ApplicantDashboardScreen> {
  final FirestoreService _service = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = _user?.uid;
      if (uid != null) {
        context.read<ApplicantProvider>().loadAll(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApplicantProvider>();
    final uid = _user?.uid;

    return DhsResponsiveShell(
      currentRoute: AppConstants.dashboardRoute,
      mobileTitle: 'Dashboard',
      mobileUserName: provider.currentApplicant?.fullName,
      child: provider.isLoading && provider.currentApplicant == null
          ? const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryPurple,
        ),
      )
          : RefreshIndicator(
        color: AppColors.primaryPurple,
        onRefresh: () async {
          if (uid != null) {
            await context.read<ApplicantProvider>().loadAll(uid);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.sizeOf(context).width >= 980 ? 24 : 14,
            vertical: 18,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: Column(
                children: [
                  _TopUtilityRow(
                    applicant: provider.currentApplicant,
                  ),
                  const SizedBox(height: 14),
                  _DashboardHero(
                    applicant: provider.currentApplicant,
                    application: provider.currentApplication,
                    payment: provider.currentPayment,
                    uid: uid,
                  ),
                  const SizedBox(height: 16),
                  _StatusCards(
                    application: provider.currentApplication,
                    payment: provider.currentPayment,
                    uid: uid,
                    service: _service,
                  ),
                  const SizedBox(height: 16),

                  _VerificationNotesPanel(uid: uid),

                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 900;
                      if (!wide) {
                        return Column(
                          children: [
                            const _QuickActionsPanel(),
                            const SizedBox(height: 16),
                            _FeaturedPlotPanel(service: _service),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            flex: 11,
                            child: _QuickActionsPanel(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 9,
                            child: _FeaturedPlotPanel(service: _service),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _RecentUpdatesPanel(
                    service: _service,
                    uid: uid,
                  ),
                  const SizedBox(height: 18),
                  const _DashboardFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopUtilityRow extends StatefulWidget {
  const _TopUtilityRow({required this.applicant});

  final ApplicantModel? applicant;

  @override
  State<_TopUtilityRow> createState() => _TopUtilityRowState();
}

class _TopUtilityRowState extends State<_TopUtilityRow> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  static const List<_DashboardSearchItem> _items = [
    _DashboardSearchItem(
      title: 'Dashboard',
      keywords: 'dashboard home',
      route: AppConstants.dashboardRoute,
      icon: Icons.dashboard_rounded,
    ),
    _DashboardSearchItem(
      title: 'Explore Plots',
      keywords: 'plot plots scheme schemes block marla kanal house',
      route: AppConstants.plotsRoute,
      icon: Icons.travel_explore_rounded,
    ),
    _DashboardSearchItem(
      title: 'Static Plot Map',
      keywords: 'static plot map location',
      route: AppConstants.mapRoute,
      icon: Icons.map_outlined,
    ),
    _DashboardSearchItem(
      title: 'Applications',
      keywords: 'application applications form submission',
      route: AppConstants.applicationRoute,
      icon: Icons.description_outlined,
    ),
    _DashboardSearchItem(
      title: 'Balloting',
      keywords: 'balloting ballot draw',
      route: AppConstants.ballotingRoute,
      icon: Icons.casino_outlined,
    ),
    _DashboardSearchItem(
      title: 'Balloting Result',
      keywords: 'balloting result results winner',
      route: AppConstants.resultRoute,
      icon: Icons.emoji_events_outlined,
    ),
    _DashboardSearchItem(
      title: 'Dealers',
      keywords: 'dealer dealers',
      route: AppConstants.dealersRoute,
      icon: Icons.groups_2_outlined,
    ),
    _DashboardSearchItem(
      title: 'Register as Dealer',
      keywords: 'register dealer registration',
      route: AppConstants.dealerRegistrationRoute,
      icon: Icons.add_business_outlined,
    ),
    _DashboardSearchItem(
      title: 'Payments',
      keywords: 'payment payments receipt fee',
      route: AppConstants.paymentRoute,
      icon: Icons.account_balance_wallet_outlined,
    ),
    _DashboardSearchItem(
      title: 'Documents',
      keywords: 'document documents upload cnic file files',
      route: AppConstants.uploadRoute,
      icon: Icons.folder_copy_outlined,
    ),
    _DashboardSearchItem(
      title: 'My Reports',
      keywords: 'report reports complaint issue',
      route: AppConstants.myReportsRoute,
      icon: Icons.summarize_outlined,
    ),
    _DashboardSearchItem(
      title: 'Contact Us',
      keywords: 'contact help support',
      route: AppConstants.contactRoute,
      icon: Icons.contact_support_outlined,
    ),
    _DashboardSearchItem(
      title: 'FAQ',
      keywords: 'faq question questions help',
      route: AppConstants.faqRoute,
      icon: Icons.quiz_outlined,
    ),
    _DashboardSearchItem(
      title: 'Profile',
      keywords: 'profile account applicant',
      route: AppConstants.profileRoute,
      icon: Icons.person_outline_rounded,
    ),
    _DashboardSearchItem(
      title: 'Settings',
      keywords: 'settings preferences',
      route: AppConstants.settingsRoute,
      icon: Icons.settings_outlined,
    ),
    _DashboardSearchItem(
      title: 'Notifications',
      keywords: 'notification notifications alerts updates',
      route: AppConstants.notificationsRoute,
      icon: Icons.notifications_none_rounded,
    ),
  ];

  List<_DashboardSearchItem> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    return _items
        .where(
          (item) =>
      item.title.toLowerCase().contains(q) ||
          item.keywords.contains(q),
    )
        .take(6)
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openResult(_DashboardSearchItem item) {
    FocusScope.of(context).unfocus();
    Navigator.pushNamed(context, item.route);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 980;

    final name = widget.applicant?.fullName.trim().isNotEmpty == true
        ? widget.applicant!.fullName.trim()
        : 'Applicant';
    final results = _results;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFE7E7F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deepPurple.withValues(alpha: .05),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) => setState(() => _query = value),
                  onSubmitted: (_) {
                    if (results.isNotEmpty) {
                      _openResult(results.first);
                    }
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.secondaryText,
                    ),
                    suffixIcon: _query.trim().isEmpty
                        ? null
                        : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    hintText: 'Search plots, schemes, or anything...',
                    hintStyle: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ),
            if (!isMobile) const SizedBox(width: 12),
            if (!isMobile)
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
            if (!isMobile) const SizedBox(width: 10),
            if (!isMobile)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppConstants.profileRoute,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.deepPurple,
                          child: Text(
                            _initials(name),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 150),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Text(
                                'Applicant',
                                style: TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.secondaryText,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (_query.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE7E7F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .07),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: results.isEmpty
                    ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No matching section found.',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
                    : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < results.length; i++) ...[
                      ListTile(
                        dense: true,
                        leading: Icon(
                          results[i].icon,
                          color: AppColors.deepPurple,
                        ),
                        title: Text(
                          results[i].title,
                          style: const TextStyle(
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppColors.secondaryText,
                        ),
                        onTap: () => _openResult(results[i]),
                      ),
                      if (i != results.length - 1)
                        const Divider(height: 1),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  static String _initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return 'A';
    return parts.map((part) => part[0].toUpperCase()).join();
  }
}

class _DashboardSearchItem {
  const _DashboardSearchItem({
    required this.title,
    required this.keywords,
    required this.route,
    required this.icon,
  });

  final String title;
  final String keywords;
  final String route;
  final IconData icon;
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.applicant,
    required this.application,
    required this.payment,
    required this.uid,
  });

  final ApplicantModel? applicant;
  final ApplicationModel? application;
  final PaymentModel? payment;
  final String? uid;

  @override
  Widget build(BuildContext context) {
    final name = applicant?.fullName.trim().isNotEmpty == true
        ? applicant!.fullName.trim()
        : 'Applicant';
    final compact = MediaQuery.sizeOf(context).width < 650;

    return FutureBuilder<_JourneySnapshot>(
      future: _JourneySnapshot.load(uid),
      builder: (context, snapshot) {
        final journey = snapshot.data ?? const _JourneySnapshot();

        return Container(
          height: compact ? 430 : 340,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.deepPurple.withValues(alpha: .18),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
            image: const DecorationImage(
              image: AssetImage(AppAssets.courtyardBackground),
              fit: BoxFit.cover,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withValues(alpha: .62),
                          Colors.black.withValues(alpha: .34),
                          Colors.black.withValues(alpha: .08),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.34, 0.62, 0.82],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.all(compact ? 20 : 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Pill(
                          icon: Icons.auto_awesome_rounded,
                          label: 'Welcome Back',
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Hello, $name',
                          maxLines: compact ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 30 : 40,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your journey to your dream home is in progress.',
                          style: TextStyle(
                            color: Color(0xFFF5F3FF),
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _HeroButton(
                              label: 'View Application',
                              icon: Icons.arrow_forward_rounded,
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppConstants.applicationRoute,
                              ),
                            ),
                            _Pill(
                              icon: Icons.calendar_month_rounded,
                              label: DateFormat('EEE, d MMM yyyy')
                                  .format(DateTime.now()),
                            ),
                          ],
                        ),
                        const Spacer(),
                        _JourneyStrip(
                          application: application,
                          payment: payment,
                          uploadExists: journey.uploadExists,
                          resultExists: journey.resultExists,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _JourneyStrip extends StatelessWidget {
  const _JourneyStrip({
    required this.application,
    required this.payment,
    required this.uploadExists,
    required this.resultExists,
  });

  final ApplicationModel? application;
  final PaymentModel? payment;
  final bool uploadExists;
  final bool resultExists;

  @override
  Widget build(BuildContext context) {
    final step = _currentStep();

    const labels = [
      'Submitted',
      'Documents',
      'Under Review',
      'Balloting',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131C58).withValues(alpha: .58),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: .18),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 520;

          return Row(
            children: List.generate(labels.length, (index) {
              final completed = index < step;
              final active = index == step;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: narrow ? 34 : 40,
                            height: narrow ? 34 : 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: completed || active
                                  ? const LinearGradient(
                                colors: [
                                  Color(0xFF6E45F5),
                                  Color(0xFF9C55F6),
                                ],
                              )
                                  : null,
                              color: completed || active
                                  ? null
                                  : Colors.white.withValues(alpha: .12),
                              border: Border.all(
                                color: active
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: .35),
                                width: active ? 2 : 1,
                              ),
                              boxShadow: active
                                  ? [
                                BoxShadow(
                                  color: AppColors.secondaryPurple
                                      .withValues(alpha: .65),
                                  blurRadius: 18,
                                  spreadRadius: 1,
                                ),
                              ]
                                  : const [],
                            ),
                            child: Center(
                              child: completed
                                  ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 20,
                              )
                                  : Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            labels[index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: narrow ? 10 : 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _subLabel(index, completed, active),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .7),
                              fontSize: narrow ? 8.5 : 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (index != labels.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 29),
                          color: index < step
                              ? const Color(0xFFA675FF)
                              : Colors.white.withValues(alpha: .25),
                        ),
                      ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }

  int _currentStep() {
    if (application == null) return 0;
    if (!uploadExists) return 1;
    if (payment == null) return 2;
    if (resultExists) return 4;
    return 3;
  }

  String _subLabel(int index, bool completed, bool active) {
    if (completed) return 'Completed';
    if (active) return 'In Progress';
    if (index == 3) return 'Upcoming';
    return 'Pending';
  }
}

class _StatusCards extends StatelessWidget {
  const _StatusCards({
    required this.application,
    required this.payment,
    required this.uid,
    required this.service,
  });

  final ApplicationModel? application;
  final PaymentModel? payment;
  final String? uid;
  final FirestoreService service;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot?>(
      future: uid == null ? Future.value(null) : service.getUpload(uid!),
      builder: (context, uploadSnapshot) {
        final upload = uploadSnapshot.data?.data() as Map<String, dynamic>?;
        final uploadStatus =
        (upload?['verificationStatus'] ?? 'Not submitted').toString();

        return FutureBuilder<DocumentSnapshot?>(
          future: uid == null
              ? Future.value(null)
              : service.getResultForApplicant(uid!),
          builder: (context, resultSnapshot) {
            final result = resultSnapshot.data?.data() as Map<String, dynamic>?;
            final resultText = result == null
                ? 'Not Available'
                : (result['status'] ??
                result['result'] ??
                result['selectionStatus'] ??
                'Available')
                .toString();

            final cards = [
              _StatusData(
                icon: Icons.description_outlined,
                title: 'Application',
                value: application?.status ?? 'Not submitted',
                tone: _tone(application?.status),
                route: AppConstants.applicationRoute,
              ),
              _StatusData(
                icon: Icons.folder_copy_outlined,
                title: 'Documents',
                value: uploadStatus,
                tone: _tone(uploadStatus),
                route: AppConstants.uploadRoute,
              ),
              _StatusData(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Payment',
                value: payment?.status ?? 'Not submitted',
                tone: _tone(payment?.status),
                route: AppConstants.paymentRoute,
              ),
              _StatusData(
                icon: Icons.emoji_events_outlined,
                title: 'Result',
                value: resultText,
                tone: _tone(resultText),
                route: AppConstants.resultRoute,
              ),
            ];

            return LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1050
                    ? 4
                    : constraints.maxWidth >= 560
                    ? 2
                    : 1;
                const gap = 12.0;
                final width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;

                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: cards
                      .map(
                        (item) => SizedBox(
                      width: width,
                      child: _StatusCard(data: item),
                    ),
                  )
                      .toList(),
                );
              },
            );
          },
        );
      },
    );
  }

  static _StatusTone _tone(String? value) {
    final text = (value ?? '').toLowerCase();
    // Check negative states before generic "selected" so "not selected"
    // can never be misclassified as a successful result.
    if (text.contains('reject') || text.contains('not selected')) {
      return _StatusTone.danger;
    }
    if (text.contains('verified') ||
        text.contains('approved') ||
        text.contains('submitted') ||
        text == 'selected' ||
        text.contains('winner')) {
      return _StatusTone.success;
    }
    if (text.contains('pending') ||
        text.contains('review') ||
        text.contains('progress')) {
      return _StatusTone.warning;
    }
    return _StatusTone.info;
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.data});

  final _StatusData data;

  @override
  Widget build(BuildContext context) {
    final tone = _toneColors(data.tone);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, data.route),
        child: Container(
          constraints: const BoxConstraints(minHeight: 112),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE6E8F0)),
            boxShadow: [
              BoxShadow(
                color: AppColors.deepPurple.withValues(alpha: .06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: tone.$2,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  data.icon,
                  color: tone.$1,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _titleCase(data.value),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tone.$1,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFF98A2B3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static (Color, Color) _toneColors(_StatusTone tone) {
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

  static String _titleCase(String value) {
    final text = value.trim();
    if (text.isEmpty) return 'Not Available';
    return text
        .split(RegExp(r'\s+'))
        .map((part) =>
    part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel();

  static const List<_ActionData> _actions = [
    _ActionData(
      label: 'Upload Documents',
      subtitle: 'Upload or manage your application documents',
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
      label: 'Track Application',
      subtitle: 'Check your application status in real time',
      icon: Icons.route_outlined,
      route: AppConstants.myReportsRoute,
    ),
    _ActionData(
      label: 'Message Center',
      subtitle: 'View important DHS notifications and updates',
      icon: Icons.forum_outlined,
      route: AppConstants.notificationsRoute,
      featured: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Quick Actions',
            trailing: TextButton(
              onPressed: () => Navigator.pushNamed(
                context,
                AppConstants.applicationRoute,
              ),
              child: const Text('View Application'),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 520 ? 2 : 1;
              const gap = 12.0;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: _actions
                    .map(
                      (action) => SizedBox(
                    width: width,
                    child: _ActionTile(data: action),
                  ),
                )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeaturedPlotPanel extends StatelessWidget {
  const _FeaturedPlotPanel({required this.service});

  final FirestoreService service;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: StreamBuilder<QuerySnapshot>(
        stream: service.getPlots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? const [];
          PlotModel? plot;

          for (final doc in docs) {
            final candidate = PlotModel.fromFirestore(doc);
            if (candidate.featured) {
              plot = candidate;
              break;
            }
          }

          if (plot == null && docs.isNotEmpty) {
            plot = PlotModel.fromFirestore(docs.first);
          }

          // Before the admin module publishes official plot inventory, show
          // the same polished preview plot used by Explore Plots and Map.
          final featuredPlot = plot ??
              DemoData.plotModels.firstWhere(
                    (item) => item.featured,
                orElse: () => DemoData.plotModels.first,
              );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(title: 'Featured Plot'),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const SizedBox(
                  height: 250,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryPurple,
                    ),
                  ),
                )
              else
                _FeaturedPlotCard(plot: featuredPlot),
            ],
          );
        },
      ),
    );
  }
}

class _FeaturedPlotCard extends StatelessWidget {
  const _FeaturedPlotCard({required this.plot});

  final PlotModel plot;

  @override
  Widget build(BuildContext context) {
    final image = plot.imageUrl.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 2.2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: image.isNotEmpty
                ? Image.network(
              image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                AppAssets.heroBackground,
                fit: BoxFit.cover,
              ),
            )
                : Image.asset(
              AppAssets.heroBackground,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Plot # ${plot.plotNumber}${plot.block.isEmpty ? '' : ', Block ${plot.block}'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _MiniFact(
              icon: Icons.crop_square_rounded,
              text: plot.size.isEmpty ? 'Size pending' : plot.size,
            ),
            _MiniFact(
              icon: Icons.park_outlined,
              text: plot.facing.isEmpty ? 'Facing pending' : plot.facing,
            ),
            _MiniFact(
              icon: Icons.add_road_rounded,
              text: plot.roadWidth.isEmpty
                  ? 'Road width pending'
                  : plot.roadWidth,
            ),
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
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            OutlinedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppConstants.mapRoute),
              child: const Text('View Details'),
            ),
          ],
        ),
      ],
    );
  }
}

class _RecentUpdatesPanel extends StatelessWidget {
  const _RecentUpdatesPanel({
    required this.service,
    required this.uid,
  });

  final FirestoreService service;
  final String? uid;

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
          const SizedBox(height: 6),
          if (uid == null)
            const _EmptyMessage(text: 'Please login to view updates.')
          else
            StreamBuilder<QuerySnapshot>(
              stream: service.getNotifications(uid!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryPurple,
                      ),
                    ),
                  );
                }

                final notifications = (snapshot.data?.docs ?? [])
                    .map(NotificationModel.fromFirestore)
                    .toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                final recent = notifications.take(4).toList();
                if (recent.isEmpty) {
                  return const _EmptyMessage(
                    text: 'No DHS updates yet.',
                  );
                }

                return Column(
                  children: recent
                      .map(
                        (item) => _NotificationRow(notification: item),
                  )
                      .toList(),
                );
              },
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
    final icon = switch (notification.type.toLowerCase()) {
      'payment' => Icons.account_balance_wallet_outlined,
      'application' => Icons.description_outlined,
      'verification' => Icons.verified_outlined,
      _ => Icons.notifications_none_rounded,
    };

    return InkWell(
      onTap: () {
        if (notification.actionRoute.isNotEmpty) {
          Navigator.pushNamed(context, notification.actionRoute);
        }
      },
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF0ECFF),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: AppColors.deepPurple, size: 21),
            ),
            const SizedBox(width: 12),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _relativeDate(notification.createdAt),
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _relativeDate(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Now';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return DateFormat('d MMM').format(date);
  }
}

class _DashboardFooter extends StatelessWidget {
  const _DashboardFooter();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        '© 2026 Digital Housing Society • Secure applicant portal',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.secondaryText,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: .16),
        foregroundColor: Colors.white,
        side: BorderSide(
          color: Colors.white.withValues(alpha: .35),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 13,
        ),
      ),
      iconAlignment: IconAlignment.end,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: Colors.white.withValues(alpha: .26),
        ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E7F0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepPurple.withValues(alpha: .05),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.trailing,
  });

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

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.data});

  final _ActionData data;

  @override
  Widget build(BuildContext context) {
    final featured = data.featured;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, data.route),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 150,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: featured
                ? const LinearGradient(
              colors: [
                Color(0xFF5B42E8),
                Color(0xFF8B4CF1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : const LinearGradient(
              colors: [
                Color(0xFFF4F2FF),
                Color(0xFFEEF5FF),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: featured
                  ? Colors.white.withValues(alpha: .15)
                  : const Color(0xFFE2E3F1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: featured
                      ? Colors.white.withValues(alpha: .16)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  data.icon,
                  color: featured ? Colors.white : AppColors.deepPurple,
                ),
              ),
              const SizedBox(height: 13),
              Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: featured ? Colors.white : AppColors.primaryText,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: featured
                      ? Colors.white.withValues(alpha: .82)
                      : AppColors.secondaryText,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniFact extends StatelessWidget {
  const _MiniFact({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF69748C)),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.secondaryText,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }
}
class _VerificationNotesPanel extends StatelessWidget {
  const _VerificationNotesPanel({required this.uid});

  final String? uid;

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return const SizedBox.shrink();
    }

    return _SectionCard(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('applicants')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(12),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryPurple,
                ),
              ),
            );
          }

          final data = snapshot.data?.data();
          final rawNotes = data?['verificationNotes'];

          final notes = rawNotes is List
              ? rawNotes
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
              : <Map<String, dynamic>>[];

          notes.sort((a, b) {
            final aTime = a['createdAt'];
            final bTime = b['createdAt'];

            if (aTime is Timestamp && bTime is Timestamp) {
              return bTime.compareTo(aTime);
            }

            return 0;
          });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(
                title: 'Verification Notes',
              ),
              const SizedBox(height: 12),

              if (notes.isEmpty)
                const _EmptyMessage(
                  text: 'No verification notes from admin yet.',
                )
              else
                Column(
                  children: notes.map((note) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F5FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE5DFFF),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.deepPurple,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.verified_user_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Admin Verification Note',
                                  style: TextStyle(
                                    color: AppColors.primaryText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  note['text']?.toString() ?? '',
                                  style: const TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _formatNoteDate(note['createdAt']),
                                  style: const TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _formatNoteDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      return '${date.day.toString().padLeft(2, '0')} '
          '${_monthName(date.month)} '
          '${date.year}, '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }

    return 'Date not available';
  }

  static String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
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

class _JourneySnapshot {
  const _JourneySnapshot({
    this.uploadExists = false,
    this.resultExists = false,
  });

  final bool uploadExists;
  final bool resultExists;

  static Future<_JourneySnapshot> load(String? uid) async {
    if (uid == null) return const _JourneySnapshot();
    final service = FirestoreService();
    try {
      final upload = await service.getUpload(uid);
      final result = await service.getResultForApplicant(uid);
      return _JourneySnapshot(
        uploadExists: upload != null,
        resultExists: result != null,
      );
    } catch (_) {
      return const _JourneySnapshot();
    }
  }
}

class _StatusData {
  const _StatusData({
    required this.icon,
    required this.title,
    required this.value,
    required this.tone,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String value;
  final _StatusTone tone;
  final String route;
}

enum _StatusTone {
  success,
  warning,
  danger,
  info,
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
