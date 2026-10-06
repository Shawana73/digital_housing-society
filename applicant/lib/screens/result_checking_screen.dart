import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/result_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/responsive_shell.dart';
import '../widgets/batch3_ui.dart';
import '../widgets/status_badge.dart';
import '../utils/result_outcome.dart';

class ResultCheckingScreen extends StatefulWidget {
  const ResultCheckingScreen({super.key});

  @override
  State<ResultCheckingScreen> createState() => _ResultCheckingScreenState();
}

class _ResultCheckingScreenState extends State<ResultCheckingScreen> {
  final _firestoreService = FirestoreService();
  bool _loading = true;
  bool _loadError = false;
  ResultModel? _result;
  // Treat drafts and absent results as pending; never invent an outcome.
  ResultOutcome _outcome = ResultOutcome.pending;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = false;
      });
    }
    if (uid == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = true;
        });
      }
      return;
    }
    try {
      // Use the logged-in applicant UID, never an entered or hardcoded ID.
      final doc = await _firestoreService.getResultForApplicant(uid);
      if (mounted) {
        setState(() {
          _result = doc == null ? null : ResultModel.fromFirestore(doc);
          final data = doc?.data() as Map<String, dynamic>? ?? {};
          _outcome = ResultOutcomeParser.fromData(data);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadError = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your result could not be loaded. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 980;
    return DhsResponsiveShell(
      currentRoute: AppConstants.resultRoute,
      mobileTitle: 'Balloting Result',
      backgroundColor: const Color(0xFFF8F6FD),
      child: RefreshIndicator(
        color: AppColors.primaryPurple,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(desktop ? 24 : 15, 18,
              desktop ? 24 : 15, 34),
          children: [DhsContentWidth(maxWidth: 900, child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DhsPageBanner(
                eyebrow: 'Your DHS account',
                title: 'Balloting result',
                subtitle: 'Check the result linked to your signed-in '
                    'applicant account. Pull down to refresh.',
                icon: Icons.how_to_reg_outlined,
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(padding: EdgeInsets.all(34),
                  child: Center(child: CircularProgressIndicator(
                      color: AppColors.primaryPurple)))
              else if (_loadError)
                _ResultErrorCard(onRetry: _load)
              else if (_result == null || _outcome == ResultOutcome.pending)
                const _NoResultCard()
              else if (_outcome == ResultOutcome.selected)
                _SelectedResultCard(result: _result!)
              else
                _NotSelectedCard(result: _result!),
            ],
          ))],
        ),
      ),
    );
  }
}

class _SelectedResultCard extends StatelessWidget {
  const _SelectedResultCard({required this.result});
  final ResultModel result;

  @override
  Widget build(BuildContext context) {
    final shareText =
        'Digital Housing Society balloting result — Plot ${result.plotNumber}, '
        '${result.plotType}, Serial ${result.serialNumber}.';
    return DhsSection(
      title: 'Selected',
      subtitle: 'Your published DHS balloting record indicates selection.',
      icon: Icons.check_circle_outline_rounded,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(alignment: Alignment.centerLeft,
            child: StatusBadge(text: 'SELECTED',
                type: StatusBadgeType.success)),
          const SizedBox(height: 15),
          DhsDetailWrap(twoColumnAt: 530, children: [
            DhsInfoBox(label: 'Plot number', value: result.plotNumber,
                icon: Icons.tag_outlined),
            DhsInfoBox(label: 'Plot type', value: result.plotType,
                icon: Icons.home_work_outlined),
            DhsInfoBox(label: 'Block / location',
                value: result.plotLocation,
                icon: Icons.location_on_outlined),
            DhsInfoBox(label: 'Serial number',
                value: result.serialNumber,
                icon: Icons.confirmation_number_outlined),
          ]),
          const SizedBox(height: 18),
          LayoutBuilder(builder: (context, constraints) {
            final shareButton = OutlinedButton.icon(
              onPressed: () => Share.share(shareText),
              icon: const Icon(Icons.share_outlined, size: 19),
              label: const Text('Share Result'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6040B5),
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: const BorderSide(color: Color(0xFFCFBFEF)),
              ),
            );
            final mapButton = PrimaryGradientButton(
              text: 'Plot Map', icon: Icons.map_outlined, height: 49,
              onPressed: () => Navigator.pushNamed(
                  context, AppConstants.mapRoute),
            );
            if (constraints.maxWidth < 430) {
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [shareButton, const SizedBox(height: 10),
                  mapButton]);
            }
            return Row(children: [
              Expanded(child: shareButton),
              const SizedBox(width: 12),
              Expanded(child: mapButton),
            ]);
          }),
        ],
      ),
    );
  }
}

class _NotSelectedCard extends StatelessWidget {
  const _NotSelectedCard({required this.result});
  final ResultModel result;

  @override
  Widget build(BuildContext context) => DhsSection(
    title: 'Not selected',
    subtitle: 'Your published result indicates that this application '
        'was not selected in the draw.',
    icon: Icons.info_outline_rounded,
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(alignment: Alignment.centerLeft,
          child: StatusBadge(text: 'NOT SELECTED',
              type: StatusBadgeType.info)),
        if (result.serialNumber.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          DhsInfoBox(label: 'Application serial',
              value: result.serialNumber),
        ],
        const SizedBox(height: 13),
        const Text('Your application record remains available in DHS.',
          style: TextStyle(color: Color(0xFF716782),
              fontSize: 13, height: 1.45)),
      ],
    ),
  );
}

class _NoResultCard extends StatelessWidget {
  const _NoResultCard();

  @override
  Widget build(BuildContext context) => const DhsSection(
    title: 'Pending publication',
    subtitle: 'No published outcome is available for this account yet.',
    icon: Icons.schedule_outlined,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusBadge(text: 'PENDING', type: StatusBadgeType.warning),
        SizedBox(height: 13),
        Text('The result will appear here when DHS publishes '
          'your official balloting record.',
          style: TextStyle(color: Color(0xFF716782),
              fontSize: 13, height: 1.45)),
      ],
    ),
  );
}

class _ResultErrorCard extends StatelessWidget {
  const _ResultErrorCard({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => DhsSection(
    title: 'Could not load result',
    subtitle: 'Check your connection and try again.',
    icon: Icons.wifi_off_outlined,
    child: OutlinedButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Try Again'),
    ),
  );
}
