import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      ('How do I submit an application?', 'Open Apply, fill your personal and plot details, then submit. A unique serial number is generated.'),
      ('Which documents are required?', 'CNIC front side, CNIC back side, signed application form and a recent applicant photograph are required.'),
      ('How does payment work?', 'Payment uses Stripe test mode. After submission, your payment status is reviewed by society administration.'),
      ('When will balloting open?', 'Admin can configure draw date/status in Firestore. The app shows eligibility and countdown.'),
      ('Where can I check my result?', 'Use Result Check and enter CNIC to search saved ballot_results records.'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Frequently Asked Questions')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text('FAQs', style: AppTextStyles.headingLarge),
          const SizedBox(height: 10),
          Text('Common questions about the Digital Housing Society applicant module.', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 16),
          ...faqs.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.borderColor), boxShadow: AppColors.premiumShadow(opacity: .14)),
                child: ExpansionTile(title: Text(e.$1, style: AppTextStyles.labelBold), childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [Align(alignment: Alignment.centerLeft, child: Text(e.$2, style: AppTextStyles.bodyMedium))]),
              )),
        ],
      ),
    );
  }
}
