import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.isPrivacy});
  final bool isPrivacy;

  @override
  Widget build(BuildContext context) {
    final title = isPrivacy ? 'Privacy Policy' : 'Terms & Conditions';
    final items = isPrivacy
        ? [
            'Applicant profile, application, payment reference, notifications and document records are stored in Firestore for the society workflow.',
            'Document records include file name, type, size, verification status and a unique serial number.',
            'Profile pictures are saved as a small encoded image in the applicant profile record.',
            'Applicant data should be handled responsibly and used only for verified society application processing.',
          ]
        : [
            'Applicants must provide accurate personal, CNIC, contact and plot preference details.',
            'Payment records are submitted in test mode/reference mode and require admin verification.',
            'Balloting eligibility depends on application, document and payment verification status.',
            'The society/admin may approve, reject, or request corrections for submitted records.',
          ];
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(title, style: AppTextStyles.headingLarge),
          const SizedBox(height: 10),
          Text('Digital Housing Society applicant module policy information.', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderColor), boxShadow: AppColors.premiumShadow(opacity: .16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ...items.map((text) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 20), const SizedBox(width: 10), Expanded(child: Text(text, style: AppTextStyles.bodyMedium))]))),
            ]),
          ),
        ],
      ),
    );
  }
}
