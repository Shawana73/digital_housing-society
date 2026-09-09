import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/admin_models.dart';
import '../../viewmodels/admin_view_models.dart';
import '../../theme/admin_theme.dart';
import '../../app_routes.dart';

class AdminDashboardViewModel extends BaseAdminViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<DashboardStat> stats = [];

  List<QuickAction> quickActions = [];

  List<AdminNotification> notifications = [];

  List<ActivityItem> activities = [];
  List<double> chartValues = [];

  String adminName = 'Admin';
  String weeklyGrowthLabel = '';

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

      final dealersSnapshot =
      await _firestore.collection('dealers').get();

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final adminDoc = await _firestore.collection('admins').doc(uid).get();
        final adminData = adminDoc.data();
        final nameFromFirestore = adminData?['name']?.toString().trim();

        if (nameFromFirestore != null && nameFromFirestore.isNotEmpty) {
          adminName = nameFromFirestore;
        } else {
          final authName = FirebaseAuth.instance.currentUser?.displayName;
          final authEmail = FirebaseAuth.instance.currentUser?.email;
          adminName = (authName != null && authName.trim().isNotEmpty)
              ? authName
              : (authEmail != null ? authEmail.split('@').first : 'Admin');
        }
      }

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
      int pendingPayments = 0;

      for (final doc in paymentsSnapshot.docs) {
        final data = doc.data();
        final amount = data['amount'];

        if (amount is num) {
          totalPayments += amount.toDouble();
        } else if (amount != null) {
          totalPayments +=
              double.tryParse(amount.toString().replaceAll(',', '')) ?? 0;
        }

        final paymentStatus = data['status']?.toString().toLowerCase();
        if (paymentStatus == 'pending' || paymentStatus == 'submitted') {
          pendingPayments++;
        }
      }


      final now = DateTime.now();
      final growthCounts = List<double>.filled(7, 0);
      double thisWeekTotal = 0;
      double lastWeekTotal = 0;

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
            thisWeekTotal++;
          } else if (difference >= 7 && difference < 14) {
            lastWeekTotal++;
          }
        }
      }

      chartValues = growthCounts;

      if (lastWeekTotal == 0) {
        weeklyGrowthLabel = thisWeekTotal > 0 ? '↑ New' : '0%';
      } else {
        final percentChange = ((thisWeekTotal - lastWeekTotal) / lastWeekTotal) * 100;
        final arrow = percentChange >= 0 ? '↑' : '↓';
        weeklyGrowthLabel = '$arrow ${percentChange.abs().toStringAsFixed(0)}%';
      }

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

      quickActions = [
        QuickAction(
          title: 'Verify Applicants',
          subtitle: '$pendingApplicants pending files',
          icon: Icons.how_to_reg_rounded,
          route: AdminRoutes.applicants,
          colors: const [AdminColors.primary, AdminColors.secondary],
        ),
        QuickAction(
          title: 'Verify Payments',
          subtitle: '$pendingPayments receipts',
          icon: Icons.payments_rounded,
          route: AdminRoutes.payments,
          colors: const [Color(0xFF10B981), Color(0xFF34D399)],
        ),
        QuickAction(
          title: 'Manage Plots',
          subtitle: '$availablePlots available',
          icon: Icons.domain_rounded,
          route: AdminRoutes.plots,
          colors: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
        ),
        const QuickAction(
          title: 'Balloting',
          subtitle: 'Live control',
          icon: Icons.auto_awesome_rounded,
          route: AdminRoutes.balloting,
          colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
        ),
        const QuickAction(
          title: 'Results',
          subtitle: 'Winner lists',
          icon: Icons.emoji_events_rounded,
          route: AdminRoutes.results,
          colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
        ),
        const QuickAction(
          title: 'Reports',
          subtitle: 'PDF & Excel',
          icon: Icons.insert_chart_rounded,
          route: AdminRoutes.reports,
          colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
        ),
        QuickAction(
          title: 'Dealers',
          subtitle: '${dealersSnapshot.docs.length} profiles',
          icon: Icons.real_estate_agent_rounded,
          route: AdminRoutes.dealers,
          colors: const [Color(0xFF7C3AED), Color(0xFFA78BFA)],
        ),
        const QuickAction(
          title: 'Plot Map',
          subtitle: 'Visual layout',
          icon: Icons.map_rounded,
          route: AdminRoutes.plotVisualization,
          colors: [Color(0xFF0891B2), Color(0xFF22D3EE)],
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
