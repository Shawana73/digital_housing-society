import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/premium_widgets.dart';
import '../../models/admin_models.dart';
import 'dashboard_widgets.dart';

class AllActivitiesScreen extends StatelessWidget {
  const AllActivitiesScreen({super.key});

  IconData _activityIcon(String type) {
    switch (type) {
      case 'payment':
        return Icons.account_balance_wallet_rounded;
      case 'verification':
        return Icons.verified_rounded;
      case 'applicant':
        return Icons.person_rounded;
      case 'plot':
        return Icons.landscape_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: AdminColors.background,
        elevation: 0,
        title: const Text('All Activities', style: TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900)),
        iconTheme: const IconThemeData(color: AdminColors.darkText),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('activity_logs')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load activities.'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return EmptyState(
              icon: Icons.manage_search_rounded,
              title: 'No activity found',
              subtitle: 'Nothing has happened yet.',
              buttonText: 'Refresh',
              onPressed: () {},
            );
          }

          final activities = docs.map((doc) {
            final data = doc.data();
            final action = data['action']?.toString() ?? '';
            final description = data['description']?.toString() ?? '';
            final type = data['type']?.toString().toLowerCase() ?? '';
            final timestamp = data['timestamp'];

            String time = '';
            if (timestamp is Timestamp) {
              final dateTime = timestamp.toDate();
              time = '${dateTime.day.toString().padLeft(2, '0')}/'
                  '${dateTime.month.toString().padLeft(2, '0')}/'
                  '${dateTime.year} '
                  '${dateTime.hour.toString().padLeft(2, '0')}:'
                  '${dateTime.minute.toString().padLeft(2, '0')}';
            }

            final positive = type == 'success' || type == 'verified' || type == 'approved';

            return ActivityItem(
              title: action,
              subtitle: description,
              time: time,
              positive: positive,
              icon: _activityIcon(type),
            );
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: activities.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DashboardActivityTile(activity: activities[i], onTap: () {}),
            ),
          );
        },
      ),
    );
  }
}