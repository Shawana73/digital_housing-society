import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_text_styles.dart';
import '../widgets/status_badge.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final service = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: const Text('My Reports')),
      body: uid == null
          ? const _EmptyState(text: 'Please login again.')
          : StreamBuilder<QuerySnapshot>(
              stream: service.getMyApplications(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple));
                final docs = [...?snapshot.data?.docs];
                docs.sort((a, b) {
                  final ad = (a.data() as Map<String, dynamic>)['submittedAt'];
                  final bd = (b.data() as Map<String, dynamic>)['submittedAt'];
                  final at = ad is Timestamp ? ad.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                  final bt = bd is Timestamp ? bd.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                  return bt.compareTo(at);
                });
                if (docs.isEmpty) return const _EmptyState(text: 'No submitted application reports yet.');
                return ListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _ReportCard(data: data);
                  },
                );
              },
            ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final date = data['submittedAt'] is Timestamp ? (data['submittedAt'] as Timestamp).toDate() : DateTime.now();
    final status = data['status']?.toString() ?? 'pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderColor), boxShadow: AppColors.premiumShadow(opacity: .18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(backgroundColor: AppColors.lightPurpleBackground, child: const Icon(Icons.article_rounded, color: AppColors.deepPurple)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(data['plotType']?.toString() ?? 'Application', style: AppTextStyles.headingSmall), Text(DateFormat('d MMM yyyy • hh:mm a').format(date), style: AppTextStyles.captionText)])),
          StatusBadge(text: status.toUpperCase(), type: badgeTypeFromStatus(status)),
        ]),
        const SizedBox(height: 14),
        _row('Serial No.', data['serialNumber']?.toString() ?? '-'),
        _row('Applicant', data['fullName']?.toString() ?? '-'),
        _row('CNIC', data['cnic']?.toString() ?? '-'),
        _row('City', data['city']?.toString() ?? '-'),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _details(context),
            icon: const Icon(Icons.visibility_rounded),
            label: const Text('View Application Details'),
          ),
        ),
      ]),
    );
  }

  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [SizedBox(width: 92, child: Text(label, style: AppTextStyles.captionText)), Expanded(child: Text(value, textAlign: TextAlign.right, style: AppTextStyles.labelBold))]));

  void _details(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('Application Details', style: AppTextStyles.headingMedium),
            const SizedBox(height: 14),
            ...data.entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 9), child: Text('${e.key}: ${e.value}', style: AppTextStyles.bodyMedium))),
          ]),
        ),
      ),
    );
  }

}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.article_outlined, size: 78, color: AppColors.hintText),
          const SizedBox(height: 12),
          Text(text, style: AppTextStyles.headingSmall, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          FilledButton.icon(onPressed: () => Navigator.pushNamed(context, AppConstants.applicationRoute), icon: const Icon(Icons.add_rounded), label: const Text('Submit Application')),
        ]),
      ),
    );
  }
}
