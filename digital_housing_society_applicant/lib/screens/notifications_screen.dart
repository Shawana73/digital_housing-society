import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../widgets/responsive_shell.dart';
import '../utils/app_text_styles.dart';
import '../widgets/notification_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final service = FirestoreService();
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final desktop =
        MediaQuery.sizeOf(context).width >= DhsResponsiveShell.desktopBreakpoint;

    return DhsResponsiveShell(
      currentRoute: AppConstants.notificationsRoute,
      mobileTitle: 'Messages',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: desktop
            ? AppBar(
                title: const Text('Notifications'),
                actions: [
                  IconButton(
                    tooltip: 'Mark all read',
                    onPressed: uid == null
                        ? null
                        : () async {
                            await service.markAllNotificationsRead(uid);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'All notifications marked as read.',
                                  ),
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.done_all_rounded),
                  ),
                  IconButton(
                    tooltip: 'Clear all',
                    onPressed:
                        uid == null ? null : () => _clearAll(context, uid),
                    icon: const Icon(Icons.delete_sweep_rounded),
                  ),
                ],
              )
            : null,
        body: uid == null
          ? const _EmptyNotifications()
          : StreamBuilder<QuerySnapshot>(
              stream: service.getNotifications(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple));
                if (snapshot.hasError) return const _EmptyNotifications(message: 'Notifications could not be loaded. Pull down to refresh later.');
                final docs = [...?snapshot.data?.docs];
                docs.sort((a, b) {
                  final ad = (a.data() as Map<String, dynamic>)['createdAt'];
                  final bd = (b.data() as Map<String, dynamic>)['createdAt'];
                  final at = ad is Timestamp ? ad.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                  final bt = bd is Timestamp ? bd.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                  return bt.compareTo(at);
                });
                final all = docs.map(NotificationModel.fromFirestore).toList();
                if (all.isEmpty) return const _EmptyNotifications();
                final unread = all.where((n) => !n.isRead).length;
                final matches = all.where((n) => n.type.toLowerCase().contains('match') || n.type.toLowerCase().contains('result')).length;
                final verification = all.where((n) => n.type.toLowerCase().contains('verification') || n.type.toLowerCase().contains('application')).length;
                final filtered = all.where((n) {
                  final t = n.type.toLowerCase();
                  if (_filter == 'unread') return !n.isRead;
                  if (_filter == 'match') return t.contains('match') || t.contains('result');
                  if (_filter == 'verification') return t.contains('verification') || t.contains('application');
                  return true;
                }).toList();
                return Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Wrap(spacing: 8, runSpacing: 8, children: [
                      _chip('all', 'All ${all.length}'),
                      _chip('unread', 'Unread $unread'),
                      _chip('match', 'Match/Result $matches'),
                      _chip('verification', 'Verification $verification'),
                    ]),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? const _EmptyNotifications(message: 'No notifications in this filter.')
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final n = filtered[index];
                              return Dismissible(
                                key: ValueKey(n.id),
                                direction: DismissDirection.endToStart,
                                background: Container(margin: const EdgeInsets.only(bottom: 14), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 22), decoration: BoxDecoration(color: AppColors.errorRed, borderRadius: BorderRadius.circular(24)), child: const Icon(Icons.delete_rounded, color: AppColors.white)),
                                onDismissed: (_) => service.deleteNotification(n.id),
                                child: NotificationCard(
                                  title: n.title,
                                  message: n.message,
                                  type: n.type,
                                  timestamp: n.createdAt,
                                  isRead: n.isRead,
                                  onTap: () async {
                                    await service.markNotificationRead(n.id);
                                    if (!context.mounted) return;
                                    _navigateByType(context, n);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ]);
              },
            ),
      ),
    );
  }

  Widget _chip(String key, String label) => ChoiceChip(label: Text(label), selected: _filter == key, selectedColor: AppColors.lightPurpleBackground, labelStyle: AppTextStyles.captionText.copyWith(color: _filter == key ? AppColors.deepPurple : AppColors.secondaryText, fontWeight: FontWeight.w700), onSelected: (_) => setState(() => _filter = key));

  Future<void> _clearAll(BuildContext context, String uid) async {
    final ok = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Clear notifications?'), content: const Text('This will remove all your notifications.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear'))]));
    if (ok == true) await service.clearNotifications(uid);
  }

  void _navigateByType(BuildContext context, NotificationModel n) {
    if (n.actionRoute.isNotEmpty) {
      Navigator.pushNamed(context, n.actionRoute);
      return;
    }
    final t = n.type.toLowerCase();
    if (t.contains('payment')) {
      Navigator.pushNamed(context, AppConstants.paymentRoute);
    } else if (t.contains('application') || t.contains('verification')) {
      Navigator.pushNamed(context, AppConstants.myReportsRoute);
    } else if (t.contains('ballot')) {
      Navigator.pushNamed(context, AppConstants.ballotingRoute);
    } else if (t.contains('result') || t.contains('match')) {
      Navigator.pushNamed(context, AppConstants.resultRoute);
    } else {
      Navigator.pushNamed(context, AppConstants.dashboardRoute);
    }
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications({this.message = 'No notifications yet'});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.notifications_none_rounded, size: 86, color: AppColors.hintText),
          const SizedBox(height: 14),
          Text(message, style: AppTextStyles.headingSmall, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('Unread, result and verification updates will appear here.', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
