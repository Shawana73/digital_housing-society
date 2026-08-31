import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/premium_widgets.dart';

class NotificationCard extends StatelessWidget {
  final AdminNotification notification;
  final VoidCallback onRead;
  final VoidCallback onDelete;
  const NotificationCard({super.key, required this.notification, required this.onRead, required this.onDelete});

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