import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.isRead,
    required this.onTap,
  });

  final String title;
  final String message;
  final String type;
  final DateTime timestamp;
  final bool isRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(type);
    final icon = _iconForType(type);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: AppColors.premiumShadow(opacity: 0.28, blurRadius: 14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(width: 4, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)))),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                          child: Icon(icon, color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(title, style: AppTextStyles.labelBold)),
                                  if (!isRead)
                                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.deepPurple, shape: BoxShape.circle)),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(message, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyMedium),
                              const SizedBox(height: 8),
                              Text(_relative(timestamp), style: AppTextStyles.captionText),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _colorForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('payment')) return AppColors.successGreen;
    if (t.contains('application')) return AppColors.primaryPurple;
    if (t.contains('ballot')) return AppColors.warningOrange;
    return AppColors.infoBlue;
  }

  IconData _iconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('payment')) return Icons.verified_rounded;
    if (t.contains('application')) return Icons.description_rounded;
    if (t.contains('ballot')) return Icons.auto_awesome_rounded;
    return Icons.notifications_rounded;
  }

  String _relative(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
