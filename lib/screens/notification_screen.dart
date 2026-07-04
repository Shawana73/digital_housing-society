import 'package:flutter/material.dart';

import '../models/admin_models.dart';
import '../theme/admin_theme.dart';
import '../viewmodels/admin_view_models.dart';
import '../widgets/admin_shell.dart';
import '../widgets/app_snack.dart';
import '../widgets/premium_widgets.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationsViewModel _viewModel = NotificationsViewModel();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_refresh);
    _viewModel.load();
  }

  void _refresh() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    _viewModel.removeListener(_refresh);
    _viewModel.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Notifications',
      selectedIndex: 0,
      searchController: _searchController,
      searchHint: 'Search notifications...',
      onSearchChanged: _viewModel.search,
      onSearchClear: () { _searchController.clear(); _viewModel.clearSearch(); },
      onFabTap: () { _viewModel.markAllRead(); showAdminSnack(context, 'All notifications marked read'); },
      fabLabel: 'Mark Read',
      fabIcon: Icons.done_all_rounded,
      isLoading: _viewModel.isLoading,
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: PremiumCard(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const GradientIconBox(icon: Icons.notifications_active_rounded),
              const SizedBox(width: 12),
              Expanded(child: Text('${_viewModel.unreadCount} unread notifications', style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 16))),
              TextButton(onPressed: () { _viewModel.markAllRead(); showAdminSnack(context, 'Marked all read'); }, child: const Text('Mark all read')),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _viewModel.filteredNotifications.isEmpty
              ? EmptyState(icon: Icons.notifications_off_rounded, title: 'No notifications', subtitle: 'Recent admin alerts will appear here.', buttonText: 'Reset', onPressed: () { _searchController.clear(); _viewModel.clearSearch(); })
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  itemCount: _viewModel.filteredNotifications.length,
                  itemBuilder: (context, index) {
                    final notification = _viewModel.filteredNotifications[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _NotificationCard(
                        notification: notification,
                        onRead: () { _viewModel.markRead(notification); showAdminSnack(context, 'Notification marked read'); },
                        onDelete: () { _viewModel.delete(notification); showAdminSnack(context, 'Notification deleted'); },
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AdminNotification notification;
  final VoidCallback onRead;
  final VoidCallback onDelete;
  const _NotificationCard({required this.notification, required this.onRead, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onRead,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GradientIconBox(icon: notification.icon, color: notification.unread ? AdminColors.primary : AdminColors.greyText),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(notification.title, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 15))),
            if (notification.unread) const Icon(Icons.circle, size: 10, color: AdminColors.primary),
          ]),
          const SizedBox(height: 5),
          Text(notification.message, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, height: 1.35)),
          const SizedBox(height: 8),
          Text(notification.time, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w900, fontSize: 11)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: onRead, icon: const Icon(Icons.done_rounded), label: const Text('Read'))),
            const SizedBox(width: 10),
            IconButton.filledTonal(onPressed: onDelete, icon: const Icon(Icons.delete_rounded), color: AdminColors.rejected),
          ]),
        ])),
      ]),
    );
  }
}
