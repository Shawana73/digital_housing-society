import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_text_styles.dart';
import '../widgets/notification_card.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final service = FirestoreService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: uid == null
                ? null
                : () async {
                    await service.markAllNotificationsRead(uid);
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All notifications marked as read.')));
                  },
            child: Text('Mark all read', style: AppTextStyles.captionText.copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: uid == null
          ? const _EmptyNotifications()
          : StreamBuilder<QuerySnapshot>(
              stream: service.getNotifications(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple));
                final docs = [...?snapshot.data?.docs];
                docs.sort((a, b) {
                  final ad = (a.data() as Map<String, dynamic>)['createdAt'];
                  final bd = (b.data() as Map<String, dynamic>)['createdAt'];
                  final at = ad is Timestamp ? ad.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                  final bt = bd is Timestamp ? bd.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                  return bt.compareTo(at);
                });
                final notifications = docs.map(NotificationModel.fromFirestore).toList();
                final unread = notifications.where((n) => !n.isRead).length;
                if (notifications.isEmpty) return const _EmptyNotifications();
                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(18),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.lightPurpleBackground, borderRadius: BorderRadius.circular(18)),
                      child: Text('$unread unread notifications', style: AppTextStyles.labelBold.copyWith(color: AppColors.deepPurple)),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final n = notifications[index];
                          return Dismissible(
                            key: ValueKey(n.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 22),
                              decoration: BoxDecoration(color: AppColors.errorRed, borderRadius: BorderRadius.circular(24)),
                              child: const Icon(Icons.delete_rounded, color: AppColors.white),
                            ),
                            onDismissed: (_) => service.deleteNotification(n.id),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: Duration(milliseconds: 260 + index * 40),
                              builder: (context, value, child) => Transform.translate(offset: Offset(24 * (1 - value), 0), child: Opacity(opacity: value, child: child)),
                              child: NotificationCard(
                                title: n.title,
                                message: n.message,
                                type: n.type,
                                timestamp: n.createdAt,
                                isRead: n.isRead,
                                onTap: () async {
                                  await service.markNotificationRead(n.id);
                                  if (!context.mounted) return;
                                  _navigateByType(context, n.type);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  void _navigateByType(BuildContext context, String type) {
    final t = type.toLowerCase();
    if (t.contains('payment')) {
      Navigator.pushNamed(context, AppConstants.paymentRoute);
    } else if (t.contains('application')) {
      Navigator.pushNamed(context, AppConstants.applicationRoute);
    } else if (t.contains('ballot')) {
      Navigator.pushNamed(context, AppConstants.ballotingRoute);
    } else if (t.contains('result')) {
      Navigator.pushNamed(context, AppConstants.resultRoute);
    } else {
      Navigator.pushNamed(context, AppConstants.dashboardRoute);
    }
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_none_rounded, size: 86, color: AppColors.hintText),
            const SizedBox(height: 14),
            Text('No notifications yet', style: AppTextStyles.headingSmall, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text('You will receive updates on your application here.', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
