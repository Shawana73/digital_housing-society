import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/applicant_model.dart';
import '../models/application_model.dart';
import '../models/notification_model.dart';
import '../models/payment_model.dart';
import '../providers/applicant_provider.dart';
import '../services/firestore_service.dart';
import '../utils/app_assets.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_text_styles.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/header_actions.dart';
import '../widgets/illustrations.dart';
import '../widgets/notification_card.dart';
import '../widgets/status_badge.dart';

class ApplicantDashboardScreen extends StatefulWidget {
  const ApplicantDashboardScreen({super.key});

  @override
  State<ApplicantDashboardScreen> createState() => _ApplicantDashboardScreenState();
}

class _ApplicantDashboardScreenState extends State<ApplicantDashboardScreen> {
  final _firestoreService = FirestoreService();
  final _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = _user?.uid;
      if (uid != null) context.read<ApplicantProvider>().loadAll(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApplicantProvider>();
    final applicant = provider.currentApplicant;
    return Scaffold(
      appBar: AppBar(
        title: Text('Digital Housing Society', style: AppTextStyles.headingSmall.copyWith(color: AppColors.white)),
        actions: [
          const NotificationBell(),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: InitialsAvatar(name: applicant?.fullName ?? _user?.displayName ?? 'Applicant'),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppConstants.applicationRoute),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_home_work_rounded),
        label: const Text('Apply'),
      ),
      body: provider.isLoading && applicant == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
          : RefreshIndicator(
              color: AppColors.primaryPurple,
              onRefresh: () async {
                final uid = _user?.uid;
                if (uid != null) await context.read<ApplicantProvider>().loadAll(uid);
              },
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  _WelcomeCard(applicant: applicant),
                  const SizedBox(height: 18),
                  _JourneyCard(application: provider.currentApplication, payment: provider.currentPayment),
                  const SizedBox(height: 18),
                  _StatusGrid(application: provider.currentApplication, payment: provider.currentPayment, uid: _user?.uid),
                  const SizedBox(height: 22),
                  _QuickActions(),
                  const SizedBox(height: 22),
                  _RecentNotifications(firestoreService: _firestoreService, uid: _user?.uid),
                ],
              ),
            ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.applicant});
  final ApplicantModel? applicant;

  @override
  Widget build(BuildContext context) {
    final name = applicant?.fullName.isNotEmpty == true ? applicant!.fullName : 'Applicant';
    final dateText = DateFormat('EEE, d MMM yyyy').format(DateTime.now());
    final compact = MediaQuery.of(context).size.width < 380;

    return Container(
      constraints: const BoxConstraints(minHeight: 188),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.premiumShadow(),
        image: const DecorationImage(image: AssetImage(AppAssets.heroBackground), fit: BoxFit.cover),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.infoBlue.withValues(alpha: .76),
                    AppColors.primaryPurple.withValues(alpha: .70),
                    AppColors.deepPurple.withValues(alpha: .66),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(child: StatusBadge(text: applicant?.profileStatus.toUpperCase() ?? 'ACTIVE', type: StatusBadgeType.success)),
                  ],
                ),
                SizedBox(height: compact ? 44 : 52),
                Text(
                  'Welcome! Your Opportunities Await',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white.withValues(alpha: .90), fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headingMedium.copyWith(color: AppColors.white, height: 1.08),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.white.withValues(alpha: .32)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: AppColors.white, size: 16),
                      const SizedBox(width: 6),
                      Flexible(child: Text(dateText, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.captionText.copyWith(color: AppColors.white, fontWeight: FontWeight.w800))),
                    ],
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

class _JourneyCard extends StatefulWidget {
  const _JourneyCard({required this.application, required this.payment});
  final ApplicationModel? application;
  final PaymentModel? payment;

  @override
  State<_JourneyCard> createState() => _JourneyCardState();
}

class _JourneyCardState extends State<_JourneyCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100), lowerBound: .84, upperBound: 1.12)..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completed = _completedStep();
    final labels = ['Apply', 'Upload', 'Pay', 'Ballot', 'Result'];
    return _PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Application Journey', style: AppTextStyles.headingSmall),
          const SizedBox(height: 18),
          Row(
            children: List.generate(labels.length, (index) {
              final done = index < completed;
              final current = index == completed;
              return Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (index > 0) Expanded(child: Container(height: 3, color: done ? AppColors.deepPurple : AppColors.borderColor)),
                        ScaleTransition(
                          scale: current ? _pulse : const AlwaysStoppedAnimation(1),
                          child: CircleAvatar(
                            radius: 15,
                            backgroundColor: done ? AppColors.deepPurple : current ? AppColors.warningOrange : AppColors.borderColor,
                            child: Icon(done ? Icons.check_rounded : current ? Icons.bolt_rounded : Icons.lock_rounded, size: 16, color: AppColors.white),
                          ),
                        ),
                        if (index < labels.length - 1) Expanded(child: Container(height: 3, color: index < completed - 1 ? AppColors.deepPurple : AppColors.borderColor)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(labels[index], style: AppTextStyles.captionText, textAlign: TextAlign.center),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  int _completedStep() {
    if (widget.application == null) return 0;
    if (widget.payment == null) return 2;
    if (widget.payment!.status.toLowerCase().contains('verified')) return 3;
    return 2;
  }
}

class _StatusGrid extends StatelessWidget {
  const _StatusGrid({required this.application, required this.payment, required this.uid});
  final ApplicationModel? application;
  final PaymentModel? payment;
  final String? uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: uid == null ? null : FirebaseFirestore.instance.collection('ballot_results').where('applicantId', isEqualTo: uid).snapshots(),
      builder: (context, resultSnap) {
        if (resultSnap.hasError) {
          return GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: MediaQuery.of(context).size.width > 650 ? 2.7 : 1.95,
            children: [
              _StatusTile(title: 'Application Status', value: application?.status ?? 'Not submitted', icon: Icons.description_rounded),
              _StatusTile(title: 'Payment Status', value: payment?.status ?? 'Not paid', icon: Icons.payments_rounded),
              _StatusTile(title: 'Balloting Status', value: 'Pending', icon: Icons.casino_rounded),
              _StatusTile(title: 'Result', value: 'Not available', icon: Icons.emoji_events_rounded),
            ],
          );
        }
        final resultDoc = resultSnap.data?.docs.isNotEmpty == true ? resultSnap.data!.docs.first.data() as Map<String, dynamic> : null;
        final selected = resultDoc?['isSelected'] == true;
        return GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: MediaQuery.of(context).size.width > 650 ? 2.7 : 1.95,
          children: [
            _StatusTile(title: 'Application Status', value: application?.status ?? 'Not submitted', icon: Icons.description_rounded),
            _StatusTile(title: 'Payment Status', value: payment?.status ?? 'Not paid', icon: Icons.payments_rounded),
            _StatusTile(title: 'Balloting Status', value: selected ? 'Completed' : 'Pending', icon: Icons.casino_rounded),
            _StatusTile(title: 'Result', value: resultDoc == null ? 'Not available' : selected ? 'Selected' : 'Not selected', icon: Icons.emoji_events_rounded),
          ],
        );
      },
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.title, required this.value, required this.icon});
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _PremiumCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: AppColors.lightPurpleBackground, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: AppColors.deepPurple, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.captionText),
                const SizedBox(height: 4),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.labelBold),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.home_work_rounded, 'Apply', AppConstants.applicationRoute),
      (Icons.drive_folder_upload_rounded, 'Upload', AppConstants.uploadRoute),
      (Icons.account_balance_wallet_rounded, 'Pay', AppConstants.paymentRoute),
      (Icons.casino_rounded, 'Balloting', AppConstants.ballotingRoute),
      (Icons.emoji_events_rounded, 'Result', AppConstants.resultRoute),
      (Icons.support_agent_rounded, 'Contact', AppConstants.contactRoute),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppTextStyles.headingSmall),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth < 390 ? (constraints.maxWidth - 10) / 2 : constraints.maxWidth < 640 ? (constraints.maxWidth - 18) / 3 : (constraints.maxWidth - 24) / 4;
            return Wrap(
              spacing: 8,
              runSpacing: 10,
              children: actions.map((action) {
                return SizedBox(
                  width: width,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => Navigator.pushNamed(context, action.$3),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
                      decoration: BoxDecoration(color: AppColors.lightPurpleBackground, borderRadius: BorderRadius.circular(18)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(action.$1, color: AppColors.deepPurple),
                          const SizedBox(height: 7),
                          Text(action.$2, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: AppTextStyles.captionText.copyWith(color: AppColors.deepPurple, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _RecentNotifications extends StatelessWidget {
  const _RecentNotifications({required this.firestoreService, required this.uid});
  final FirestoreService firestoreService;
  final String? uid;

  @override
  Widget build(BuildContext context) {
    if (uid == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Recent Notifications', style: AppTextStyles.headingSmall)),
            TextButton(onPressed: () => Navigator.pushNamed(context, AppConstants.notificationsRoute), child: const Text('See all')),
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: firestoreService.getNotifications(uid!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple));
            if (snapshot.hasError) return _EmptyMessage(icon: Icons.notifications_none_rounded, text: 'Notifications could not be loaded.');
            final docs = [...?snapshot.data?.docs];
            docs.sort((a, b) {
              final ad = (a.data() as Map<String, dynamic>)['createdAt'];
              final bd = (b.data() as Map<String, dynamic>)['createdAt'];
              final at = ad is Timestamp ? ad.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
              final bt = bd is Timestamp ? bd.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
              return bt.compareTo(at);
            });
            final recent = docs.take(3).map(NotificationModel.fromFirestore).toList();
            if (recent.isEmpty) return _EmptyMessage(icon: Icons.notifications_none_rounded, text: 'No notifications yet');
            return Column(
              children: recent.map((n) => NotificationCard(title: n.title, message: n.message, type: n.type, timestamp: n.createdAt, isRead: n.isRead, onTap: () => Navigator.pushNamed(context, AppConstants.notificationsRoute))).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.child, this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderColor), boxShadow: AppColors.premiumShadow(opacity: .28)),
      child: child,
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderColor)),
      child: Row(children: [Icon(icon, color: AppColors.hintText), const SizedBox(width: 10), Expanded(child: Text(text, style: AppTextStyles.bodyMedium))]),
    );
  }
}
