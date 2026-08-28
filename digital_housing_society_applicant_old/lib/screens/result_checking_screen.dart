import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/result_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_text_styles.dart';
import '../utils/formatters_validators.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/header_actions.dart';
import '../widgets/illustrations.dart';

class ResultCheckingScreen extends StatefulWidget {
  const ResultCheckingScreen({super.key});

  @override
  State<ResultCheckingScreen> createState() => _ResultCheckingScreenState();
}

class _ResultCheckingScreenState extends State<ResultCheckingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cnicController = TextEditingController();
  final _firestoreService = FirestoreService();
  bool _loading = false;
  ResultModel? _result;
  bool _searched = false;

  @override
  void dispose() {
    _cnicController.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _searched = true;
      _result = null;
    });
    try {
      final doc = await _firestoreService.getResult(_cnicController.text.trim());
      if (mounted) setState(() => _result = doc == null ? null : ResultModel.fromFirestore(doc));
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check Result'), actions: const [NotificationBell(), SizedBox(width: 8)]),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          IllustrationBox(painter: MagnifierPainter(), height: 165),
          const SizedBox(height: 18),
          Text('Search by CNIC', style: AppTextStyles.headingLarge, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('Enter your national ID number to check result', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 22),
          Form(
            key: _formKey,
            child: AppTextField(
              label: 'CNIC',
              hint: '35202-1234567-8',
              controller: _cnicController,
              prefixIcon: Icons.badge_rounded,
              keyboardType: TextInputType.number,
              inputFormatters: [CnicInputFormatter()],
              validator: Validators.cnic,
            ),
          ),
          const SizedBox(height: 16),
          PrimaryGradientButton(text: 'Check Result', onPressed: _check, isLoading: _loading),
          const SizedBox(height: 22),
          if (_loading) const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
          if (!_loading && _searched && _result == null) const _NoResultCard(),
          if (!_loading && _result != null && _result!.isSelected) _WinnerCard(result: _result!),
          if (!_loading && _result != null && !_result!.isSelected) _NotSelectedCard(result: _result!),
        ],
      ),
    );
  }
}

class _WinnerCard extends StatelessWidget {
  const _WinnerCard({required this.result});
  final ResultModel result;

  @override
  Widget build(BuildContext context) {
    final shareText = 'Congratulations! Selected in Digital Housing Society balloting. Plot: ${result.plotNumber}, ${result.plotType}, Serial: ${result.serialNumber}';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.successLightBackground, borderRadius: BorderRadius.circular(28), border: Border.all(color: AppColors.successGreen.withValues(alpha: .25))),
      child: Column(
        children: [
          SizedBox(height: 145, child: CustomPaint(painter: TrophyPainter(), child: Container())),
          Text('Congratulations!', style: AppTextStyles.headingLarge.copyWith(color: AppColors.successGreen), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('You have been selected in the balloting!', style: AppTextStyles.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 18),
          _detail('Plot Number', result.plotNumber),
          _detail('Plot Type', result.plotType),
          _detail('Block / Location', result.plotLocation),
          _detail('Serial Number', result.serialNumber),
          const SizedBox(height: 16),
          OutlinedButton.icon(onPressed: () => Share.share(shareText), icon: const Icon(Icons.share_rounded), label: const Text('Share Result')),
          const SizedBox(height: 8),
          PrimaryGradientButton(text: 'View on Plot Map', onPressed: () => Navigator.pushNamed(context, AppConstants.mapRoute)),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [Text(label, style: AppTextStyles.captionText), const Spacer(), Flexible(child: Text(value.isEmpty ? '-' : value, textAlign: TextAlign.right, style: AppTextStyles.labelBold))]),
      );
}

class _NotSelectedCard extends StatelessWidget {
  const _NotSelectedCard({required this.result});
  final ResultModel result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: AppColors.errorLightBackground, borderRadius: BorderRadius.circular(28), border: Border.all(color: AppColors.errorRed.withValues(alpha: .2))),
      child: Column(children: [
        const Icon(Icons.house_siding_rounded, size: 82, color: AppColors.hintText),
        const SizedBox(height: 14),
        Text('Not Selected This Time', style: AppTextStyles.headingMedium, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Your application was included in the balloting, but was not selected in this draw.', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Better luck next time', style: AppTextStyles.labelBold.copyWith(color: AppColors.errorRed)),
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
        const Icon(Icons.search_off_rounded, size: 76, color: AppColors.hintText),
        const SizedBox(height: 12),
        Text('No result found for this CNIC', style: AppTextStyles.headingSmall, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text('Make sure you entered the correct CNIC.', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
      ]),
    );
  }
}
