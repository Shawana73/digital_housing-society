import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

enum StatusBadgeType { success, warning, error, info }

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.text, required this.type});

  final String text;
  final StatusBadgeType type;

  @override
  Widget build(BuildContext context) {
    final bg = switch (type) {
      StatusBadgeType.success => AppColors.successLightBackground,
      StatusBadgeType.warning => AppColors.warningLightBackground,
      StatusBadgeType.error => AppColors.errorLightBackground,
      StatusBadgeType.info => AppColors.lightPurpleBackground,
    };
    final fg = switch (type) {
      StatusBadgeType.success => AppColors.successGreen,
      StatusBadgeType.warning => AppColors.warningOrange,
      StatusBadgeType.error => AppColors.errorRed,
      StatusBadgeType.info => AppColors.deepPurple,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        text,
        style: AppTextStyles.captionText.copyWith(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}

StatusBadgeType badgeTypeFromStatus(String status) {
  final s = status.toLowerCase();
  if (s.contains('verified') || s.contains('approved') || s.contains('selected') || s.contains('active') || s.contains('complete')) {
    return StatusBadgeType.success;
  }
  if (s.contains('reject') || s.contains('failed') || s.contains('not')) return StatusBadgeType.error;
  if (s.contains('pending') || s.contains('review') || s.contains('awaiting') || s.contains('upcoming')) return StatusBadgeType.warning;
  return StatusBadgeType.info;
}
