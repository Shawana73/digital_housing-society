import 'package:flutter/material.dart';

import '../data/dummy_data.dart';
import '../models/admin_models.dart';

class BaseAdminViewModel extends ChangeNotifier {
  bool isLoading = true;
  String query = '';

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 450));
    isLoading = false;
    notifyListeners();
  }

  void search(String value) {
    query = value.trim().toLowerCase();
    notifyListeners();
  }

  void clearSearch() {
    query = '';
    notifyListeners();
  }
}

class AdminDashboardViewModel extends BaseAdminViewModel {
  final stats = DummyData.dashboardStats();
  final quickActions = DummyData.quickActions();
  final activities = DummyData.activities();
  final notifications = DummyData.notifications();
  final chartValues = const [18.0, 24.0, 21.0, 32.0, 38.0, 45.0, 58.0];

  List<ActivityItem> get filteredActivities {
    if (query.isEmpty) return activities;
    return activities
        .where((a) => a.title.toLowerCase().contains(query) || a.subtitle.toLowerCase().contains(query))
        .toList();
  }

  int get unreadCount => notifications.where((n) => n.unread).length;

  void markAllRead() {
    for (final notification in notifications) {
      notification.unread = false;
    }
    notifyListeners();
  }
}

class ApplicantVerificationViewModel extends BaseAdminViewModel {
  final List<Applicant> applicants = DummyData.applicants();
  String selectedFilter = 'All';

  List<String> get filters => ['All', 'Pending', 'Verified', 'Rejected'];

  List<Applicant> get filteredApplicants {
    return applicants.where((applicant) {
      final matchesQuery = query.isEmpty ||
          applicant.name.toLowerCase().contains(query) ||
          applicant.cnic.toLowerCase().contains(query) ||
          applicant.phone.toLowerCase().contains(query) ||
          applicant.email.toLowerCase().contains(query);
      final matchesFilter = selectedFilter == 'All' || applicant.status.label == selectedFilter;
      return matchesQuery && matchesFilter;
    }).toList();
  }

  void setFilter(String value) {
    selectedFilter = value;
    notifyListeners();
  }

  void approve(Applicant applicant) {
    applicant.status = VerificationStatus.verified;
    notifyListeners();
  }

  void reject(Applicant applicant) {
    applicant.status = VerificationStatus.rejected;
    notifyListeners();
  }
}

class PaymentVerificationViewModel extends BaseAdminViewModel {
  final List<PaymentRecord> payments = DummyData.payments();
  String selectedFilter = 'All';

  List<String> get filters => ['All', 'Pending', 'Verified', 'Rejected'];

  List<PaymentRecord> get filteredPayments {
    return payments.where((payment) {
      final matchesQuery = query.isEmpty ||
          payment.applicantName.toLowerCase().contains(query) ||
          payment.transactionId.toLowerCase().contains(query) ||
          payment.amount.toLowerCase().contains(query);
      final matchesFilter = selectedFilter == 'All' || payment.status.label == selectedFilter;
      return matchesQuery && matchesFilter;
    }).toList();
  }

  void setFilter(String value) {
    selectedFilter = value;
    notifyListeners();
  }

  void approve(PaymentRecord payment) {
    payment.status = PaymentStatus.verified;
    notifyListeners();
  }

  void reject(PaymentRecord payment) {
    payment.status = PaymentStatus.rejected;
    notifyListeners();
  }
}

class PlotManagementViewModel extends BaseAdminViewModel {
  final List<SocietyPlot> plots = DummyData.plots();
  String selectedFilter = 'All';

  List<String> get filters => ['All', 'Available', 'Booked', 'Allocated'];

  List<SocietyPlot> get filteredPlots {
    return plots.where((plot) {
      final matchesQuery = query.isEmpty ||
          plot.id.toLowerCase().contains(query) ||
          plot.size.toLowerCase().contains(query) ||
          plot.location.toLowerCase().contains(query) ||
          plot.price.toLowerCase().contains(query);
      final matchesFilter = selectedFilter == 'All' || plot.status.label == selectedFilter;
      return matchesQuery && matchesFilter;
    }).toList();
  }

  void setFilter(String value) {
    selectedFilter = value;
    notifyListeners();
  }

  void updateStatus(SocietyPlot plot, PlotStatus status) {
    plot.status = status;
    notifyListeners();
  }

  void deletePlot(SocietyPlot plot) {
    plots.remove(plot);
    notifyListeners();
  }
}

class AddPlotViewModel extends ChangeNotifier {
  final plotId = TextEditingController();
  final plotSize = TextEditingController();
  final price = TextEditingController();
  final location = TextEditingController();
  final description = TextEditingController();

  void reset() {
    plotId.clear();
    plotSize.clear();
    price.clear();
    location.clear();
    description.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    plotId.dispose();
    plotSize.dispose();
    price.dispose();
    location.dispose();
    description.dispose();
    super.dispose();
  }
}

class BallotingViewModel extends BaseAdminViewModel {
  BallotingLiveStatus status = BallotingLiveStatus.ready;
  double progress = 0.0;

  int totalApplicants = 1284;
  int verifiedApplicants = 946;
  int availablePlots = 148;

  String get statusLabel {
    switch (status) {
      case BallotingLiveStatus.ready:
        return 'Ready';
      case BallotingLiveStatus.running:
        return 'Running';
      case BallotingLiveStatus.paused:
        return 'Paused';
      case BallotingLiveStatus.stopped:
        return 'Stopped';
      case BallotingLiveStatus.completed:
        return 'Completed';
    }
  }

  void start() {
    status = BallotingLiveStatus.running;
    progress = 0.42;
    notifyListeners();
  }

  void pause() {
    status = BallotingLiveStatus.paused;
    notifyListeners();
  }

  void resume() {
    status = BallotingLiveStatus.running;
    progress = 0.72;
    notifyListeners();
  }

  void stop() {
    status = BallotingLiveStatus.stopped;
    progress = 0.0;
    notifyListeners();
  }

  void complete() {
    status = BallotingLiveStatus.completed;
    progress = 1.0;
    notifyListeners();
  }
}

class ResultViewModel extends BaseAdminViewModel {
  final List<BallotingResult> results = DummyData.results();
  String selectedFilter = 'All';

  List<String> get filters => ['All', 'Selected', 'Not Selected'];

  List<BallotingResult> get filteredResults {
    return results.where((result) {
      final matchesQuery = query.isEmpty ||
          result.applicantName.toLowerCase().contains(query) ||
          result.cnic.toLowerCase().contains(query) ||
          result.plotNo.toLowerCase().contains(query);
      final matchesFilter = selectedFilter == 'All' ||
          (selectedFilter == 'Selected' && result.selected) ||
          (selectedFilter == 'Not Selected' && !result.selected);
      return matchesQuery && matchesFilter;
    }).toList();
  }

  void setFilter(String value) {
    selectedFilter = value;
    notifyListeners();
  }
}

class ReportsViewModel extends BaseAdminViewModel {
  final reports = DummyData.reports();
  final chartValues = const [65.0, 82.0, 44.0, 72.0, 91.0, 76.0, 88.0];

  List<ReportCardModel> get filteredReports {
    if (query.isEmpty) return reports;
    return reports.where((r) => r.title.toLowerCase().contains(query) || r.fileType.toLowerCase().contains(query)).toList();
  }
}

class DealerVerificationViewModel extends BaseAdminViewModel {
  final List<Dealer> dealers = DummyData.dealers();
  String selectedFilter = 'All';

  List<String> get filters => ['All', 'Pending', 'Verified', 'Rejected'];

  List<Dealer> get filteredDealers {
    return dealers.where((dealer) {
      final matchesQuery = query.isEmpty ||
          dealer.name.toLowerCase().contains(query) ||
          dealer.cnic.toLowerCase().contains(query) ||
          dealer.phone.toLowerCase().contains(query) ||
          dealer.agency.toLowerCase().contains(query);
      final matchesFilter = selectedFilter == 'All' || dealer.status.label == selectedFilter;
      return matchesQuery && matchesFilter;
    }).toList();
  }

  void setFilter(String value) {
    selectedFilter = value;
    notifyListeners();
  }

  void approve(Dealer dealer) {
    dealer.status = VerificationStatus.verified;
    notifyListeners();
  }

  void reject(Dealer dealer) {
    dealer.status = VerificationStatus.rejected;
    notifyListeners();
  }
}

class PlotVisualizationViewModel extends BaseAdminViewModel {
  final List<SocietyPlot> plots = DummyData.plots();
  double zoom = 1.0;

  List<SocietyPlot> get filteredPlots {
    if (query.isEmpty) return plots;
    return plots.where((p) => p.id.toLowerCase().contains(query) || p.location.toLowerCase().contains(query)).toList();
  }

  void zoomIn() {
    zoom = (zoom + 0.1).clamp(0.8, 1.5);
    notifyListeners();
  }

  void zoomOut() {
    zoom = (zoom - 0.1).clamp(0.8, 1.5);
    notifyListeners();
  }
}

class NotificationsViewModel extends BaseAdminViewModel {
  final List<AdminNotification> notifications = DummyData.notifications();

  List<AdminNotification> get filteredNotifications {
    if (query.isEmpty) return notifications;
    return notifications.where((n) => n.title.toLowerCase().contains(query) || n.message.toLowerCase().contains(query)).toList();
  }

  int get unreadCount => notifications.where((n) => n.unread).length;

  void markAllRead() {
    for (final notification in notifications) {
      notification.unread = false;
    }
    notifyListeners();
  }

  void markRead(AdminNotification notification) {
    notification.unread = false;
    notifyListeners();
  }

  void delete(AdminNotification notification) {
    notifications.remove(notification);
    notifyListeners();
  }
}

class ProfileViewModel extends BaseAdminViewModel {
  String name = 'Ayesha Khan';
  String email = 'admin@digitalhousing.com';
  String phone = '+92 300 1234567';
  String role = 'Super Admin';
}
