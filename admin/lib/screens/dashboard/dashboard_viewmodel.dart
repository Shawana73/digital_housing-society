import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/admin_models.dart';
import '../../viewmodels/admin_view_models.dart';
import '../../theme/admin_theme.dart';
import '../../app_routes.dart';
import 'dashboard_widgets.dart';

class AdminDashboardViewModel extends BaseAdminViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool hasError = false;

  List<DashboardStat> stats = [];
  List<AdminNotification> notifications = [];
  List<ActivityItem> activities = [];

  String adminName = 'Admin';

  // ============================================================
  // APPLICANTS
  // ============================================================
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _applicantsSub;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _applicantDocs = [];
  List<DateTime> _applicantDates = [];

  // ============================================================
  // APPLICATIONS (source of truth for verification status)
  // ============================================================
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _applicationsSub;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _applicationDocs = [];

  // ============================================================
  // PLOTS
  // ============================================================
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _plotsSub;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _plotDocs = [];
  List<DateTime> _plotDates = [];

  // ============================================================
  // PAYMENTS
  // ============================================================
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _paymentsSub;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _paymentDocs = [];
  List<DateTime> _paymentDates = [];
  double _totalPaymentsAmount = 0;

  // ============================================================
  // DEALERS
  // ============================================================
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _dealersSub;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _dealerDocs = [];

  // ============================================================
  // ACTIVITIES & NOTIFICATIONS
  // ============================================================
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _activitiesSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _notificationsSub;

  static const List<Map<String, dynamic>> _screenShortcuts = [
    {'title': 'Applicants', 'keywords': ['applicant', 'applicants', 'verify applicant'], 'route': AdminRoutes.applicants, 'icon': Icons.people_alt_rounded},
    {'title': 'Payments', 'keywords': ['payment', 'payments', 'verify payment'], 'route': AdminRoutes.payments, 'icon': Icons.payments_rounded},
    {'title': 'Plot Management', 'keywords': ['plot', 'plots', 'manage plots'], 'route': AdminRoutes.plots, 'icon': Icons.domain_rounded},
    {'title': 'Add Plot', 'keywords': ['add plot', 'new plot'], 'route': AdminRoutes.addPlot, 'icon': Icons.add_home_rounded},
    {'title': 'Balloting', 'keywords': ['balloting', 'ballot'], 'route': AdminRoutes.balloting, 'icon': Icons.shuffle_rounded},
    {'title': 'Balloting Results', 'keywords': ['result', 'results', 'balloting result'], 'route': AdminRoutes.results, 'icon': Icons.emoji_events_rounded},
    {'title': 'Reports', 'keywords': ['report', 'reports'], 'route': AdminRoutes.reports, 'icon': Icons.insert_chart_rounded},
    {'title': 'Dealers', 'keywords': ['dealer', 'dealers'], 'route': AdminRoutes.dealers, 'icon': Icons.storefront_rounded},
    {'title': 'Plot Visualization', 'keywords': ['plot map', 'visualization', 'society map'], 'route': AdminRoutes.plotVisualization, 'icon': Icons.map_rounded},
    {'title': 'Notifications', 'keywords': ['notification', 'notifications'], 'route': AdminRoutes.notifications, 'icon': Icons.notifications_rounded},
    {'title': 'Profile', 'keywords': ['profile', 'my profile'], 'route': AdminRoutes.profile, 'icon': Icons.person_rounded},
  ];

  // ============================================================
  // APPLICATION OVERVIEW CHART
  // ============================================================
  ChartPeriod chartPeriod = ChartPeriod.week;
  List<double> chartValues = [];
  List<String> chartLabels = [];
  int totalThisPeriod = 0;
  String peakLabel = '-';
  double peakValue = 0;
  double averageValue = 0;

  void setChartPeriod(ChartPeriod period) {
    chartPeriod = period;
    _computeChartData();
    notifyListeners();
  }

  // ============================================================
  // APPLICATION STATUS BREAKDOWN
  // ============================================================
  int totalApplicants = 0;
  int verifiedApplicants = 0;
  int pendingApplicants = 0;
  int rejectedApplicants = 0;
  List<BreakdownSlice> applicationStatusSlices = [];

  // ============================================================
  // PLOT AVAILABILITY BREAKDOWN
  // ============================================================
  int totalPlots = 0;
  int availablePlots = 0;
  int allocatedPlots = 0;
  int bookedPlots = 0;
  List<BreakdownSlice> plotSlices = [];

  // ============================================================
  // DEALERS & PENDING PAYMENTS
  // ============================================================
  int totalDealers = 0;
  int verifiedDealers = 0;
  int pendingPayments = 0;

  @override
  Future<void> load() async {
    isLoading = true;
    hasError = false;
    notifyListeners();

    _subscribeApplicants();
    _subscribeApplications();
    _subscribePlots();
    _subscribePayments();
    _subscribeDealers();
    _subscribeActivities();
    _subscribeNotifications();

    try {
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
    } catch (e) {
      debugPrint('Dashboard Firestore error: $e');
      hasError = true;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // APPLICANTS
  // ============================================================
  void _subscribeApplicants() {
    _applicantsSub?.cancel();
    _applicantsSub = _firestore.collection('applicants').snapshots().listen((snapshot) {
      _applicantDocs = snapshot.docs;
      _processApplicants();
      notifyListeners();
    }, onError: (e) {
      debugPrint('Applicants stream error: $e');
    });
  }

  void _subscribeApplications() {
    _applicationsSub?.cancel();
    _applicationsSub = _firestore.collection('applications').snapshots().listen((snapshot) {
      _applicationDocs = snapshot.docs;
      _processApplicants();
      notifyListeners();
    }, onError: (e) {
      debugPrint('Applications stream error: $e');
    });
  }

  void _processApplicants() {
    verifiedApplicants = 0;
    pendingApplicants = 0;
    rejectedApplicants = 0;
    _applicantDates = [];

    // Build applicantId (uid) -> application status map — same source of
    // truth used by the Applicant Verification screen.
    final Map<String, String> statusByUid = {};
    for (final appDoc in _applicationDocs) {
      final appData = appDoc.data();
      final applicantId = appData['applicantId']?.toString().trim();
      final status = appData['status']?.toString().trim().toLowerCase() ?? '';
      if (applicantId != null && applicantId.isNotEmpty) {
        statusByUid[applicantId] = status;
      }
    }

    for (final doc in _applicantDocs) {
      final data = doc.data();
      final uid = data['uid']?.toString().trim();
      final status = uid != null ? statusByUid[uid] : null;

      if (status == 'verified' || status == 'approved') {
        verifiedApplicants++;
      } else if (status == 'rejected' || status == 'reject') {
        rejectedApplicants++;
      } else {
        pendingApplicants++;
      }

      final createdAt = data['createdAt'];
      if (createdAt is Timestamp) _applicantDates.add(createdAt.toDate());
    }
    totalApplicants = _applicantDocs.length;

    applicationStatusSlices = [
      BreakdownSlice(
        label: 'Verified',
        value: verifiedApplicants,
        percent: totalApplicants == 0 ? 0 : verifiedApplicants / totalApplicants,
        color: AdminColors.primary,
      ),
      BreakdownSlice(
        label: 'Pending',
        value: pendingApplicants,
        percent: totalApplicants == 0 ? 0 : pendingApplicants / totalApplicants,
        color: const Color(0xFFF59E0B),
      ),
      BreakdownSlice(
        label: 'Rejected',
        value: rejectedApplicants,
        percent: totalApplicants == 0 ? 0 : rejectedApplicants / totalApplicants,
        color: AdminColors.rejected,
      ),
    ];

    _computeChartData();
    _rebuildStats();
  }

  // ============================================================
  // PLOTS
  // ============================================================
  void _subscribePlots() {
    _plotsSub?.cancel();
    _plotsSub = _firestore.collection('plots').snapshots().listen((snapshot) {
      _plotDocs = snapshot.docs;
      _processPlots();
      notifyListeners();
    }, onError: (e) {
      debugPrint('Plots stream error: $e');
    });
  }

  void _processPlots() {
    availablePlots = 0;
    allocatedPlots = 0;
    bookedPlots = 0;
    _plotDates = [];

    for (final doc in _plotDocs) {
      final data = doc.data();
      final status = data['status']?.toString().toLowerCase();

      if (status == 'available') {
        availablePlots++;
      } else if (status == 'allocated') {
        allocatedPlots++;
      } else if (status == 'booked') {
        bookedPlots++;
      }

      final createdAt = data['createdAt'];
      if (createdAt is Timestamp) _plotDates.add(createdAt.toDate());
    }
    totalPlots = _plotDocs.length;

    plotSlices = [
      BreakdownSlice(
        label: 'Available',
        value: availablePlots,
        percent: totalPlots == 0 ? 0 : availablePlots / totalPlots,
        color: AdminColors.primary,
      ),
      BreakdownSlice(
        label: 'Allocated',
        value: allocatedPlots,
        percent: totalPlots == 0 ? 0 : allocatedPlots / totalPlots,
        color: const Color(0xFF6366F1),
      ),
      BreakdownSlice(
        label: 'Booked',
        value: bookedPlots,
        percent: totalPlots == 0 ? 0 : bookedPlots / totalPlots,
        color: const Color(0xFFF59E0B),
      ),
    ];

    _rebuildStats();
  }

  // ============================================================
  // PAYMENTS
  // ============================================================
  void _subscribePayments() {
    _paymentsSub?.cancel();
    _paymentsSub = _firestore.collection('payments').snapshots().listen((snapshot) {
      _paymentDocs = snapshot.docs;
      _processPayments();
      notifyListeners();
    }, onError: (e) {
      debugPrint('Payments stream error: $e');
    });
  }

  void _processPayments() {
    double totalPayments = 0;
    pendingPayments = 0;
    _paymentDates = [];

    for (final doc in _paymentDocs) {
      final data = doc.data();
      final amount = data['amount'];

      if (amount is num) {
        totalPayments += amount.toDouble();
      } else if (amount != null) {
        totalPayments += double.tryParse(amount.toString().replaceAll(',', '')) ?? 0;
      }

      final paymentStatus = data['status']?.toString().toLowerCase();
      if (paymentStatus == 'pending' || paymentStatus == 'submitted') {
        pendingPayments++;
      }

      final createdAt = data['createdAt'] ?? data['date'];
      if (createdAt is Timestamp) _paymentDates.add(createdAt.toDate());
    }

    _totalPaymentsAmount = totalPayments;
    _rebuildStats();
  }

  // ============================================================
  // DEALERS
  // ============================================================
  void _subscribeDealers() {
    _dealersSub?.cancel();
    _dealersSub = _firestore.collection('dealers').snapshots().listen((snapshot) {
      _dealerDocs = snapshot.docs;
      _processDealers();
      notifyListeners();
    }, onError: (e) {
      debugPrint('Dealers stream error: $e');
    });
  }

  void _processDealers() {
    totalDealers = _dealerDocs.length;
    int verifiedCount = 0;

    for (final doc in _dealerDocs) {
      final data = doc.data();
      final status = data['status']?.toString().toLowerCase();
      if (status == 'verified') verifiedCount++;
    }

    verifiedDealers = verifiedCount;
    _rebuildStats();
  }

  // ============================================================
  // ACTIVITIES
  // ============================================================
  void _subscribeActivities() {
    _activitiesSub?.cancel();
    _activitiesSub = _firestore
        .collection('activity_logs')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) {
      activities = snapshot.docs.map((doc) {
        final data = doc.data();
        final action = data['action']?.toString() ?? '';
        final description = data['description']?.toString() ?? '';
        final type = data['type']?.toString().toLowerCase() ?? '';
        final timestamp = data['timestamp'];

        String time = '';
        if (timestamp is Timestamp) {
          final dateTime = timestamp.toDate();
          time = '${dateTime.day.toString().padLeft(2, '0')}/'
              '${dateTime.month.toString().padLeft(2, '0')}/'
              '${dateTime.year} '
              '${dateTime.hour.toString().padLeft(2, '0')}:'
              '${dateTime.minute.toString().padLeft(2, '0')}';
        }

        final positive = type == 'success' || type == 'verified' || type == 'approved';

        return ActivityItem(
          title: action,
          subtitle: description,
          time: time,
          positive: positive,
          icon: _activityIcon(type),
        );
      }).toList();
      notifyListeners();
    }, onError: (e) {
      debugPrint('Activities stream error: $e');
    });
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================
  void _subscribeNotifications() {
    _notificationsSub?.cancel();
    _notificationsSub = _firestore.collection('notifications').snapshots().listen((snapshot) {
      notifications = snapshot.docs.map((doc) {
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
      notifyListeners();
    }, onError: (e) {
      debugPrint('Notifications stream error: $e');
    });
  }

  // ============================================================
  // STAT CARDS — rebuilt whenever any contributing source changes
  // ============================================================
  void _rebuildStats() {
    final applicantMonthly = _monthlyCounts(_applicantDates);
    final plotMonthly = _monthlyCounts(_plotDates);
    final paymentMonthly = _monthlyCounts(_paymentDates);

    stats = [
      DashboardStat(
        title: 'Total Applicants',
        value: totalApplicants.toString(),
        trend: '${_percentLabel(applicantMonthly.thisMonth, applicantMonthly.lastMonth)} this month',
        icon: Icons.people_alt_rounded,
        color: AdminColors.primary,
        route: AdminRoutes.applicants,
      ),
      DashboardStat(
        title: 'Total Plots',
        value: totalPlots.toString(),
        trend: '${_percentLabel(plotMonthly.thisMonth, plotMonthly.lastMonth)} this month',
        icon: Icons.domain_rounded,
        color: const Color(0xFF6366F1),
        route: AdminRoutes.plots,
      ),
      DashboardStat(
        title: 'Total Payments',
        value: 'PKR ${_formatAmount(_totalPaymentsAmount)}',
        trend: '${_percentLabel(paymentMonthly.thisMonth, paymentMonthly.lastMonth)} this month',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFFF59E0B),
        route: AdminRoutes.payments,
      ),
      DashboardStat(
        title: 'Verified Dealers',
        value: verifiedDealers.toString(),
        trend: '$totalDealers total',
        icon: Icons.verified_rounded,
        color: const Color(0xFF14B8A6),
        route: AdminRoutes.dealers,
      ),
      DashboardStat(
        title: 'Pending Payments',
        value: pendingPayments.toString(),
        trend: 'Needs review',
        icon: Icons.pending_actions_rounded,
        color: const Color(0xFFEF4444),
        route: AdminRoutes.payments,
      ),
    ];
  }

  // ============================================================
  // CHART DATA
  // ============================================================
  static const List<String> _monthAbbr = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  static const List<String> _weekdayAbbr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  void _computeChartData() {
    final now = DateTime.now();

    switch (chartPeriod) {
      case ChartPeriod.today:
        const bucketCount = 6;
        final labels = ['12am', '4am', '8am', '12pm', '4pm', '8pm'];
        final values = List<double>.filled(bucketCount, 0);
        for (final date in _applicantDates) {
          if (date.year == now.year && date.month == now.month && date.day == now.day) {
            final bucket = (date.hour ~/ 4).clamp(0, bucketCount - 1);
            values[bucket]++;
          }
        }
        chartLabels = labels;
        chartValues = values;
        break;

      case ChartPeriod.week:
        final labels = <String>[];
        final values = List<double>.filled(7, 0);
        for (int i = 6; i >= 0; i--) {
          final day = now.subtract(Duration(days: i));
          labels.add(_weekdayAbbr[(day.weekday - 1).clamp(0, 6)]);
        }
        for (final date in _applicantDates) {
          final difference = DateTime(now.year, now.month, now.day)
              .difference(DateTime(date.year, date.month, date.day))
              .inDays;
          if (difference >= 0 && difference < 7) {
            values[6 - difference]++;
          }
        }
        chartLabels = labels;
        chartValues = values;
        break;

      case ChartPeriod.month:
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final labels = List<String>.generate(daysInMonth, (i) => '${i + 1}');
        final values = List<double>.filled(daysInMonth, 0);
        for (final date in _applicantDates) {
          if (date.year == now.year && date.month == now.month) {
            values[date.day - 1]++;
          }
        }
        chartLabels = labels;
        chartValues = values;
        break;

      case ChartPeriod.year:
        final labels = List<String>.from(_monthAbbr);
        final values = List<double>.filled(12, 0);
        for (final date in _applicantDates) {
          if (date.year == now.year) {
            values[date.month - 1]++;
          }
        }
        chartLabels = labels;
        chartValues = values;
        break;
    }

    totalThisPeriod = chartValues.fold<double>(0.0, (a, b) => a + b).round();

    if (chartValues.isEmpty || totalThisPeriod == 0) {
      peakLabel = '-';
      peakValue = 0;
      averageValue = 0;
    } else {
      var peakIndex = 0;
      for (int i = 1; i < chartValues.length; i++) {
        if (chartValues[i] > chartValues[peakIndex]) peakIndex = i;
      }
      peakValue = chartValues[peakIndex];
      peakLabel = '${chartLabels[peakIndex]} — ${peakValue.toInt()}';
      averageValue = totalThisPeriod / chartValues.length;
    }
  }

  ({int thisMonth, int lastMonth}) _monthlyCounts(List<DateTime> dates) {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);

    int thisMonth = 0;
    int lastMonth = 0;
    for (final d in dates) {
      if (!d.isBefore(thisMonthStart)) {
        thisMonth++;
      } else if (!d.isBefore(lastMonthStart) && d.isBefore(thisMonthStart)) {
        lastMonth++;
      }
    }
    return (thisMonth: thisMonth, lastMonth: lastMonth);
  }

  String _percentLabel(int current, int previous) {
    if (previous == 0) {
      return current > 0 ? '+New' : '+0.0%';
    }
    final change = ((current - previous) / previous) * 100;
    final sign = change >= 0 ? '+' : '-';
    return '$sign${change.abs().toStringAsFixed(1)}%';
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
    final isWhole = amount == amount.roundToDouble();
    final fixed = isWhole ? amount.toInt().toString() : amount.toStringAsFixed(2);
    final parts = fixed.split('.');
    final digits = parts[0].split('').reversed.toList();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if ((i + 1) % 3 == 0 && i + 1 != digits.length) buffer.write(',');
    }
    final withCommas = buffer.toString().split('').reversed.join();
    return parts.length > 1 ? '$withCommas.${parts[1]}' : withCommas;
  }

  // ============================================================
  // GLOBAL SEARCH
  // ============================================================
  List<DashboardSearchResult> get searchResults {
    if (query.isEmpty) return [];
    final results = <DashboardSearchResult>[];

    for (final shortcut in _screenShortcuts) {
      final keywords = (shortcut['keywords'] as List).cast<String>();
      final matches = keywords.any((k) => k.contains(query)) || (shortcut['title'] as String).toLowerCase().contains(query);
      if (matches) {
        results.add(DashboardSearchResult(
          title: shortcut['title'] as String,
          subtitle: 'Go to ${shortcut['title']}',
          icon: shortcut['icon'] as IconData,
          type: DashboardSearchResultType.screen,
          route: shortcut['route'] as String,
        ));
      }
    }

    for (final doc in _applicantDocs) {
      final data = doc.data();
      final name = (data['fullName'] ?? '').toString().toLowerCase();
      final cnic = (data['cnic'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      if (name.contains(query) || cnic.contains(query) || email.contains(query)) {
        results.add(DashboardSearchResult(
          title: (data['fullName'] ?? 'Unknown Applicant').toString(),
          subtitle: 'CNIC: ${data['cnic'] ?? 'N/A'}',
          icon: Icons.person_rounded,
          type: DashboardSearchResultType.applicant,
          doc: doc,
        ));
      }
    }

    for (final doc in _plotDocs) {
      final data = doc.data();
      final plotId = (data['plotId'] ?? '').toString().toLowerCase();
      final location = (data['location'] ?? '').toString().toLowerCase();
      if (plotId.contains(query) || location.contains(query)) {
        results.add(DashboardSearchResult(
          title: 'Plot ${data['plotId'] ?? ''}',
          subtitle: (data['location'] ?? '').toString(),
          icon: Icons.location_on_rounded,
          type: DashboardSearchResultType.plot,
          doc: doc,
        ));
      }
    }

    return results;
  }

  List<ActivityItem> get filteredActivities {
    if (query.isEmpty) return activities;
    return activities
        .where((activity) =>
    activity.title.toLowerCase().contains(query) ||
        activity.subtitle.toLowerCase().contains(query))
        .toList();
  }

  int get unreadCount => notifications.where((n) => n.unread).length;

  void markAllRead() async {
    try {
      final batch = _firestore.batch();
      for (final notification in notifications) {
        batch.update(_firestore.collection('notifications').doc(notification.id), {'unread': false});
        notification.unread = false;
      }
      await batch.commit();
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking dashboard notifications read: $e');
    }
  }

  @override
  void dispose() {
    _applicantsSub?.cancel();
    _applicationsSub?.cancel();
    _plotsSub?.cancel();
    _paymentsSub?.cancel();
    _dealersSub?.cancel();
    _activitiesSub?.cancel();
    _notificationsSub?.cancel();
    super.dispose();
  }
}