import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/result_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_text_styles.dart';
import '../widgets/custom_button.dart';
import '../widgets/illustrations.dart';
import '../widgets/responsive_shell.dart';

class ResultCheckingScreen extends StatefulWidget {
  const ResultCheckingScreen({super.key});

  @override
  State<ResultCheckingScreen> createState() => _ResultCheckingScreenState();
}

class _ResultCheckingScreenState extends State<ResultCheckingScreen> {
  final _firestoreService = FirestoreService();
  bool _loading = true;
  ResultModel? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final doc = await _firestoreService.getResultForApplicant(uid);
      if (mounted) setState(() => _result = doc == null ? null : ResultModel.fromFirestore(doc));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your result could not be loaded. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DhsResponsiveShell(
      currentRoute: AppConstants.resultRoute,
      mobileTitle: 'Balloting Result',
      child: RefreshIndicator(
        color: AppColors.primaryPurple,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.sizeOf(context).width >= 980 ? 24 : 14,
            vertical: 18,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 940),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF245CDD),
                            Color(0xFF693FE1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Text(
                        'My Balloting Result',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    IllustrationBox(
                      painter: MagnifierPainter(),
                      height: 140,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Official Balloting Result',
                      style: AppTextStyles.headingLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'For privacy and accuracy, DHS loads only the result linked to your signed-in applicant account.',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 22),
                    if (_loading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      )
                    else if (_result == null)
                      const _NoResultCard()
                    else if (_result!.isSelected)
                      _WinnerCard(result: _result!)
                    else
                      _NotSelectedCard(result: _result!),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WinnerCard extends StatelessWidget {
  const _WinnerCard({required this.result});
  final ResultModel result;

  @override
  Widget build(BuildContext context) {
    final shareText = 'Digital Housing Society balloting result — Plot ${result.plotNumber}, ${result.plotType}, Serial ${result.serialNumber}.';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.successLightBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.successGreen.withValues(alpha: .25)),
      ),
      child: Column(
        children: [
          SizedBox(height: 145, child: CustomPaint(painter: TrophyPainter(), child: Container())),
          Text('Congratulations!', style: AppTextStyles.headingLarge.copyWith(color: AppColors.successGreen), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Your application has been selected in the official DHS balloting.', style: AppTextStyles.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 18),
          _detail('Plot Number', result.plotNumber),
          _detail('Plot Type', result.plotType),
          _detail('Block / Location', result.plotLocation),
          _detail('Serial Number', result.serialNumber),
          const SizedBox(height: 16),
          OutlinedButton.icon(onPressed: () => Share.share(shareText), icon: const Icon(Icons.share_rounded), label: const Text('Share Result')),
          const SizedBox(height: 8),
          PrimaryGradientButton(text: 'View Society Plot Map', onPressed: () => Navigator.pushNamed(context, AppConstants.mapRoute)),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Text(label, style: AppTextStyles.captionText),
          const Spacer(),
          Flexible(child: Text(value.isEmpty ? '-' : value, textAlign: TextAlign.right, style: AppTextStyles.labelBold)),
        ]),
      );
}

class _NotSelectedCard extends StatelessWidget {
  const _NotSelectedCard({required this.result});
  final ResultModel result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.errorLightBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.errorRed.withValues(alpha: .2)),
      ),
      child: Column(children: [
        const Icon(Icons.home_work_outlined, size: 76, color: AppColors.hintText),
        const SizedBox(height: 14),
        Text('Not Selected This Time', style: AppTextStyles.headingMedium, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Your eligible application participated in the draw but was not selected. Your record remains safely available in DHS.', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
      ]),
    );
  }
}

class _NoResultCard extends StatelessWidget {
  const _NoResultCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: AppColors.borderColor)),
      child: Column(children: [
        const Icon(Icons.schedule_rounded, size: 70, color: AppColors.deepPurple),
        const SizedBox(height: 12),
        Text('Result Not Published Yet', style: AppTextStyles.headingSmall, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text('Your personal result will appear here when the society administration publishes the official draw results.', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
      ]),
    );
  }
}
