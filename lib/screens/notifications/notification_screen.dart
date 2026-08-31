import 'package:flutter/material.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_shell.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/premium_widgets.dart';
import 'notification_viewmodel.dart';
import 'notification_widgets.dart';

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

  void _refresh() {
    if (mounted) setState(() {});
  }

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
      onSearchClear: () {
        _searchController.clear();
        _viewModel.clearSearch();
      },
      onFabTap: () {
        _viewModel.markAllRead();
        showAdminSnack(context, 'All notifications marked read');
      },
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
              TextButton(
                  onPressed: () {
                    _viewModel.markAllRead();
                    showAdminSnack(context, 'Marked all read');
                  },
                  child: const Text('Mark all read')),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _viewModel.filteredNotifications.isEmpty
              ? EmptyState(
              icon: Icons.notifications_off_rounded,
              title: 'No notifications',
              subtitle: 'Recent admin alerts will appear here.',
              buttonText: 'Reset',
              onPressed: () {
                _searchController.clear();
                _viewModel.clearSearch();
              })
              : ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            itemCount: _viewModel.filteredNotifications.length,
            itemBuilder: (context, index) {
              final notification = _viewModel.filteredNotifications[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: NotificationCard(
                  notification: notification,
                  onRead: () {
                    _viewModel.markRead(notification);
                    showAdminSnack(context, 'Notification marked read');
                  },
                  onDelete: () {
                    _viewModel.delete(notification);
                    showAdminSnack(context, 'Notification deleted');
                  },
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}