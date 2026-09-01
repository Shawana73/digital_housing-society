import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_text_styles.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key, this.dark = false});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService().getNotifications(uid),
      builder: (context, snapshot) {
        final unread = snapshot.data?.docs.where((d) {
              final data = d.data() as Map<String, dynamic>? ?? {};
              return data['isRead'] == false;
            }).length ??
            0;
        return IconButton(
          onPressed: () => Navigator.pushNamed(context, AppConstants.notificationsRoute),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications_rounded, color: dark ? AppColors.primaryText : AppColors.white),
              if (unread > 0)
                Positioned(
                  right: -5,
                  top: -7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.errorRed, borderRadius: BorderRadius.circular(99)),
                    child: Text(unread > 9 ? '9+' : '$unread', style: AppTextStyles.captionText.copyWith(color: AppColors.white, fontSize: 9)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.name, this.radius = 18, this.onTap});
  final String name;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? 'A'
        : name.trim().split(RegExp(r'\s+')).take(2).map((e) => e.isEmpty ? '' : e[0].toUpperCase()).join();
    return InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onTap ?? () => Navigator.pushNamed(context, AppConstants.profileRoute),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.deepPurple,
        child: Text(initials, style: AppTextStyles.labelBold.copyWith(color: AppColors.white)),
      ),
    );
  }
}
