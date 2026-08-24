import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../data/dummy_data.dart';
import '../models/admin_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/plot_model.dart';
import '../services/firestore_service.dart';
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
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  List<PlotModel> plots = [];

  String selectedFilter = 'All';

  List<String> get filters => [
    'All',
    'Available',
    'Booked',
    'Allocated',
  ];

  List<PlotModel> get filteredPlots {
    return plots.where((plot) {
      final matchesQuery =
          query.isEmpty ||
              plot.plotId.toLowerCase().contains(query) ||
              plot.plotSize.toLowerCase().contains(query) ||
              plot.location.toLowerCase().contains(query) ||
              plot.price.toString().contains(query);

      final matchesFilter =
          selectedFilter == 'All' ||
              plot.status.toLowerCase() ==
                  selectedFilter.toLowerCase();

      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      final snapshot =
      await _firestore.collection('plots').get();

      print('TOTAL PLOTS FROM FIRESTORE: ${snapshot.docs.length}');

      for (final doc in snapshot.docs) {
        print('DOCUMENT ID: ${doc.id}');
        print('DOCUMENT DATA: ${doc.data()}');
      }
      plots = snapshot.docs.map((doc) {
        return PlotModel.fromMap(
          doc.data(),
          doc.id,
        );
      }).toList();

      print('PLOTS LIST LENGTH: ${plots.length}');
    } catch (e) {
      print('ERROR LOADING PLOTS: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  void setFilter(String value) {
    selectedFilter = value;
    notifyListeners();
  }

  Future<void> updateStatus(
      PlotModel plot,
      String status,
      ) async {
    try {
      await _firestore
          .collection('plots')
          .doc(plot.documentId)
          .update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });

      await load();
    } catch (e) {
      print('Error updating plot: $e');
    }
  }

  Future<void> deletePlot(PlotModel plot) async {
    try {
      await _firestore
          .collection('plots')
          .doc(plot.documentId)
          .delete();

      plots.removeWhere(
            (item) => item.documentId == plot.documentId,
      );

      notifyListeners();
    } catch (e) {
      print('Error deleting plot: $e');
    }
  }
}

class AddPlotViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final plotId = TextEditingController();
  final plotSize = TextEditingController();
  final price = TextEditingController();
  final location = TextEditingController();
  final description = TextEditingController();

  Future<void> savePlot() async {
    final plot = PlotModel(
      documentId: '',
      plotId: plotId.text.trim(),
      plotSize: plotSize.text.trim(),
      price: double.tryParse(price.text.trim()) ?? 0,
      location: location.text.trim(),
      description: description.text.trim(),
      status: "Available",
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );

    await _firestoreService.addPlot(plot);
  }

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ReportModel> reports = [];

  final chartValues = const [
    65.0,
    82.0,
    44.0,
    72.0,
    91.0,
    76.0,
    88.0,
  ];

  List<ReportModel> get filteredReports {
    return reports.where((report) {
      final matchesQuery =
          query.isEmpty ||
              report.title.toLowerCase().contains(query) ||
              report.fileType.toLowerCase().contains(query);

      return matchesQuery;
    }).toList();
  }

  @override
  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      final snapshot =
      await _firestore.collection('reports').get();

      reports = snapshot.docs.map((doc) {
        return ReportModel.fromMap(
          doc.data(),
          doc.id,
        );
      }).toList();
    } catch (e) {
      print('Error loading reports: $e');
    }

    isLoading = false;
    notifyListeners();
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<AdminNotification> notifications = [];

  @override
  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    try {
      final snapshot =
      await _firestore.collection('notifications').get();
      print('Notifications found: ${snapshot.docs.length}');
      notifications = snapshot.docs.map((doc) {
        final data = doc.data();

        return AdminNotification(
          id: doc.id,
          title: data['title'] ?? '',
          message: data['message'] ?? '',
          time: data['time'] ?? '',
          icon: Icons.notifications_rounded,
          unread: data['unread'] ?? true,
        );
      }).toList();
    } catch (e) {
      print('Error loading notifications: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  List<AdminNotification> get filteredNotifications {
    if (query.isEmpty) return notifications;

    return notifications.where((notification) {
      return notification.title.toLowerCase().contains(query) ||
          notification.message.toLowerCase().contains(query);
    }).toList();
  }

  int get unreadCount =>
      notifications.where((notification) => notification.unread).length;

  Future<void> markAllRead() async {
    try {
      for (final notification in notifications) {
        await _firestore
            .collection('notifications')
            .doc(notification.id)
            .update({
          'unread': false,
        });

        notification.unread = false;
      }

      notifyListeners();
    } catch (e) {
      print('Error marking all notifications read: $e');
    }
  }

  Future<void> markRead(AdminNotification notification) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .update({
        'unread': false,
      });

      notification.unread = false;

      notifyListeners();
    } catch (e) {
      print('Error marking notification read: $e');
    }
  }

  Future<void> delete(AdminNotification notification) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .delete();

      notifications.removeWhere(
            (item) => item.id == notification.id,
      );

      notifyListeners();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }
}

class ProfileViewModel extends BaseAdminViewModel {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  String name = '';
  String email = '';
  String phone = '';
  String role = '';

  @override
  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        print('No admin is currently logged in.');
        return;
      }

      final doc = await _firestore
          .collection('admins')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;

        name = data['name'] ?? '';
        email = data['email'] ?? '';
        phone = data['phone'] ?? '';
        role = data['role'] ?? '';

        print('Admin profile loaded successfully.');
      } else {
        print('Admin profile document not found.');
      }
    } catch (e) {
      print('Error loading admin profile: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String newName,
    required String newEmail,
    required String newPhone,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        print('No admin is currently logged in.');
        return false;
      }

      await _firestore
          .collection('admins')
          .doc(user.uid)
          .update({
        'name': newName.trim(),
        'email': newEmail.trim(),
        'phone': newPhone.trim(),
      });

      name = newName.trim();
      email = newEmail.trim();
      phone = newPhone.trim();

      notifyListeners();

      return true;
    } catch (e) {
      print('Error updating admin profile: $e');
      return false;
    }
  }
}
