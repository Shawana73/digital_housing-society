import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/admin_models.dart';
import '../../data/dummy_data.dart';
import '../../viewmodels/admin_view_models.dart';
import '../../theme/admin_theme.dart';
import '../../app_routes.dart';

class AdminDashboardViewModel extends BaseAdminViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<DashboardStat> stats = [];

  final quickActions = DummyData.quickActions();

  List<AdminNotification> notifications = [];

  List<ActivityItem> activities = [];
  List<double> chartValues = [];

  @override
  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      final applicantsSnapshot =
      await _firestore.collection('applicants').get();

      final plotsSnapshot =
      await _firestore.collection('plots').get();

      final paymentsSnapshot =
      await _firestore.collection('payments').get();

      final activitiesSnapshot = await _firestore
          .collection('activity_logs')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      final notificationsSnapshot = await _firestore
          .collection('notifications')
          .get();

      int verifiedApplicants = 0;
      int pendingApplicants = 0;
      int rejectedApplicants = 0;

      for (final doc in applicantsSnapshot.docs) {
        final data = doc.data();
        final status = data['profileStatus']?.toString().toLowerCase();

        if (status == 'verified') {
          verifiedApplicants++;
        } else if (status == 'pending') {
          pendingApplicants++;
        } else if (status == 'rejected') {
          rejectedApplicants++;
        }
      }

      int availablePlots = 0;
      int allocatedPlots = 0;

      for (final doc in plotsSnapshot.docs) {
        final data = doc.data();
        final status = data['status']?.toString().toLowerCase();

        if (status == 'available') {
          availablePlots++;
        } else if (status == 'allocated') {
          allocatedPlots++;
        }
      }

      double totalPayments = 0;

      for (final doc in paymentsSnapshot.docs) {
        final data = doc.data();
        final amount = data['amount'];

        if (amount is num) {
          totalPayments += amount.toDouble();
        } else if (amount != null) {
          totalPayments +=
              double.tryParse(amount.toString().replaceAll(',', '')) ?? 0;
        }
      }

      final now = DateTime.now();
      final growthCounts = List<double>.filled(7, 0);

      for (final doc in applicantsSnapshot.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'];

        if (createdAt is Timestamp) {
          final date = createdAt.toDate();

          final difference = DateTime(
            now.year,
            now.month,
            now.day,
          ).difference(
            DateTime(
              date.year,
              date.month,
              date.day,
            ),
          ).inDays;

          if (difference >= 0 && difference < 7) {
            growthCounts[6 - difference]++;
          }
        }
      }

      chartValues = growthCounts;

      activities = activitiesSnapshot.docs.map((doc) {
        final data = doc.data();

        final action = data['action']?.toString() ?? '';
        final description = data['description']?.toString() ?? '';
        final type = data['type']?.toString().toLowerCase() ?? '';

        final timestamp = data['timestamp'];

        String time = '';

        if (timestamp is Timestamp) {
          final dateTime = timestamp.toDate();

          time =
          '${dateTime.day.toString().padLeft(2, '0')}/'
              '${dateTime.month.toString().padLeft(2, '0')}/'
              '${dateTime.year} '
              '${dateTime.hour.toString().padLeft(2, '0')}:'
              '${dateTime.minute.toString().padLeft(2, '0')}';
        }

        final positive = type == 'success' ||
            type == 'verified' ||
            type == 'approved';

        return ActivityItem(
          title: action,
          subtitle: description,
          time: time,
          positive: positive,
          icon: _activityIcon(type),
        );
      }).toList();

      notifications = notificationsSnapshot.docs.map((doc) {
        final data = doc.data();

        return AdminNotification(
          id: doc.id,
          title: data['title']?.toString() ?? '',
          message: data['message']?.toString() ?? '',
          time: data['time']?.toString() ?? '',
          icon: Icons.notifications_rounded,
          unread: data['unread'] ?? true,
        );
      }).toList();

      stats = [
        DashboardStat(
          title: 'Total Applicants',
          value: applicantsSnapshot.docs.length.toString(),
          trend: 'Live',
          icon: Icons.people_alt_rounded,
          color: AdminColors.primary,
          route: AdminRoutes.applicants,
        ),
        DashboardStat(
          title: 'Verified Applicants',
          value: verifiedApplicants.toString(),
          trend: 'Live',
          icon: Icons.verified_rounded,
          color: AdminColors.success,
          route: AdminRoutes.applicants,
        ),
        DashboardStat(
          title: 'Pending Applicants',
          value: pendingApplicants.toString(),
          trend: 'Live',
          icon: Icons.pending_actions_rounded,
          color: AdminColors.warning,
          route: AdminRoutes.applicants,
        ),
        DashboardStat(
          title: 'Rejected Applicants',
          value: rejectedApplicants.toString(),
          trend: 'Live',
          icon: Icons.cancel_rounded,
          color: AdminColors.rejected,
          route: AdminRoutes.applicants,
        ),
        DashboardStat(
          title: 'Total Payments',
          value: 'PKR ${_formatAmount(totalPayments)}',
          trend: 'Live',
          icon: Icons.account_balance_wallet_rounded,
          color: AdminColors.secondary,
          route: AdminRoutes.payments,
        ),
        DashboardStat(
          title: 'Plots Available',
          value: availablePlots.toString(),
          trend: 'Live',
          icon: Icons.landscape_rounded,
          color: const Color(0xFF14B8A6),
          route: AdminRoutes.plots,
        ),
        DashboardStat(
          title: 'Plots Allocated',
          value: allocatedPlots.toString(),
          trend: 'Live',
          icon: Icons.home_work_rounded,
          color: const Color(0xFF6366F1),
          route: AdminRoutes.plots,
        ),
        DashboardStat(
          title: 'Active Balloting',
          value: 'Live',
          trend: '87%',
          icon: Icons.auto_awesome_rounded,
          color: const Color(0xFFEC4899),
          route: AdminRoutes.balloting,
        ),
      ];
    } catch (e) {
      debugPrint('Dashboard Firestore error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

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

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }

    return amount.toStringAsFixed(2);
  }

  List<ActivityItem> get filteredActivities {
    if (query.isEmpty) {
      return activities;
    }

    return activities
        .where(
          (activity) =>
      activity.title.toLowerCase().contains(query) ||
          activity.subtitle.toLowerCase().contains(query),
    )
        .toList();
  }

  int get unreadCount {
    return notifications.where((notification) => notification.unread).length;
  }

  void markAllRead() async {
    try {
      for (final notification in notifications) {
        await _firestore
            .collection('notifications')
            .doc(notification.id)
            .update({'unread': false});

        notification.unread = false;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error marking dashboard notifications read: $e');
    }
  }
}
