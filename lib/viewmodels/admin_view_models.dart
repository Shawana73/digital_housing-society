import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../theme/admin_theme.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Applicant> applicants = [];
  String selectedFilter = 'All';

  List<String> get filters => [
    'All',
    'Pending',
    'Verified',
    'Rejected',
  ];

  List<Applicant> get filteredApplicants {
    return applicants.where((applicant) {
      final searchText = query.trim().toLowerCase();

      final matchesQuery = searchText.isEmpty ||
          applicant.name.toLowerCase().contains(searchText) ||
          applicant.cnic.toLowerCase().contains(searchText) ||
          applicant.phone.toLowerCase().contains(searchText) ||
          applicant.email.toLowerCase().contains(searchText);

      final matchesFilter = selectedFilter == 'All' ||
          applicant.status.label == selectedFilter;

      return matchesQuery && matchesFilter;
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────
  // Load applicants from Firestore
  // ─────────────────────────────────────────────────────────────

  @override
  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      // Get all applicants
      final applicantsSnapshot =
      await _firestore.collection('applicants').get();

      // Get all applications
      final applicationsSnapshot =
      await _firestore.collection('applications').get();

      // Create a lookup map:
      // applications.applicantId == applicants.uid
      final Map<String, QueryDocumentSnapshot<Map<String, dynamic>>>
      applicationByApplicantId = {};

      for (final doc in applicationsSnapshot.docs) {
        final data = doc.data();

        final applicantId = data['applicantId']?.toString().trim();

        if (applicantId != null && applicantId.isNotEmpty) {
          applicationByApplicantId[applicantId] = doc;
        }
      }

      final loadedApplicants = <Applicant>[];

      for (final applicantDoc in applicantsSnapshot.docs) {
        final data = applicantDoc.data();

        final uid = data['uid']?.toString().trim();

        if (uid == null || uid.isEmpty) {
          continue;
        }

        // Find corresponding application
        final applicationDoc = applicationByApplicantId[uid];
        final applicationData = applicationDoc?.data();

        final name =
            data['fullName']?.toString().trim() ?? 'Unknown Applicant';

        final cnic = data['cnic']?.toString().trim() ?? '';

        final phone = data['phone']?.toString().trim() ??
            applicationData?['contactNumber']?.toString().trim() ??
            '';

        final email = data['email']?.toString().trim() ?? '';

        final address = data['address']?.toString().trim() ??
            applicationData?['address']?.toString().trim() ??
            '';

        final status = _parseVerificationStatus(
          applicationData?['status'],
        );

        loadedApplicants.add(
          Applicant(
            // Use ApplicationId when available because this is more
            // useful on the admin side; otherwise use UID.
            id: applicationData?['ApplicationId']?.toString().trim() ??
                uid,

            name: name,
            cnic: cnic,
            phone: phone,
            email: email,
            address: address,

            // Occupation doesn't exist in the current backend schema.
            occupation: '',

            avatarLetters: _getAvatarLetters(name),

            // Applicant documents are not part of the collections
            // you provided, so keep this empty for now.
            documents: const [],

            status: status,
          ),
        );
      }

      applicants = loadedApplicants;

      debugPrint(
        'Applicant Verification: ${applicants.length} applicants loaded.',
      );
    } catch (e, stackTrace) {
      debugPrint('Error loading applicants: $e');
      debugPrintStack(stackTrace: stackTrace);
    }

    isLoading = false;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // Parse Firestore status
  // ─────────────────────────────────────────────────────────────

  VerificationStatus _parseVerificationStatus(dynamic value) {
    final status = value?.toString().trim().toLowerCase();

    switch (status) {
      case 'verified':
      case 'approved':
        return VerificationStatus.verified;

      case 'rejected':
      case 'reject':
        return VerificationStatus.rejected;

      case 'pending':
      case 'submitted':
      case 'under review':
      case 'under_review':
      case '':
      case null:
        return VerificationStatus.pending;

      default:
        return VerificationStatus.pending;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Search filter
  // ─────────────────────────────────────────────────────────────

  void setFilter(String value) {
    selectedFilter = value;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // Approve applicant
  // ─────────────────────────────────────────────────────────────

  Future<void> approve(Applicant applicant) async {
    await _updateApplicationStatus(
      applicant,
      VerificationStatus.verified,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Reject applicant
  // ─────────────────────────────────────────────────────────────

  Future<void> reject(Applicant applicant) async {
    await _updateApplicationStatus(
      applicant,
      VerificationStatus.rejected,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Update status in applications collection
  // ─────────────────────────────────────────────────────────────

  Future<void> _updateApplicationStatus(
      Applicant applicant,
      VerificationStatus newStatus,
      ) async {
    try {
      final newStatusLabel = newStatus.label;

      // 1. Find the applicant document using CNIC.
      // CNIC is already being loaded from the applicants collection.
      final applicantQuery = await _firestore
          .collection('applicants')
          .where('cnic', isEqualTo: applicant.cnic)
          .limit(1)
          .get();

      if (applicantQuery.docs.isEmpty) {
        throw Exception(
          'Applicant not found for ${applicant.name}',
        );
      }

      final applicantDoc = applicantQuery.docs.first;
      final applicantData = applicantDoc.data();

      final uid = applicantData['uid']?.toString().trim();

      if (uid == null || uid.isEmpty) {
        throw Exception(
          'Applicant UID not found for ${applicant.name}',
        );
      }

      // 2. Find the corresponding application.
      // Primary relationship:
      // applications.applicantId == applicants.uid
      final applicationQuery = await _firestore
          .collection('applications')
          .where('applicantId', isEqualTo: uid)
          .limit(1)
          .get();
      debugPrint('Looking for ApplicationId: ${applicant.id}');
      debugPrint('Found applications: ${applicationQuery.docs.length}');
      if (applicationQuery.docs.isEmpty) {
        throw Exception(
          'Application not found for ${applicant.name}',
        );
      }

      final applicationDoc = applicationQuery.docs.first;

      // 3. Update BOTH collections together.
      final batch = _firestore.batch();

      batch.update(applicationDoc.reference, {
        'status': newStatusLabel,
      });

      batch.update(applicantDoc.reference, {
        'profileStatus': newStatusLabel,
      });

      await batch.commit();

      // 4. Update local UI only after Firestore succeeds.
      applicant.status = newStatus;

      notifyListeners();

      debugPrint(
        '${applicant.name} status updated successfully to $newStatusLabel',
      );
    }  catch (e, stackTrace) {
  debugPrint('🔥 FIRESTORE UPDATE ERROR: $e');
  debugPrint('🔥 ERROR TYPE: ${e.runtimeType}');
  debugPrintStack(stackTrace: stackTrace);
  rethrow;
}
  }

  // ─────────────────────────────────────────────────────────────
  // Avatar initials
  // ─────────────────────────────────────────────────────────────

  String _getAvatarLetters(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first.substring(
        0,
        parts.first.length >= 2 ? 2 : 1,
      ).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
class ApplicantDetailsViewModel extends BaseAdminViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Applicant? applicant;

  Map<String, dynamic>? applicantData;
  Map<String, dynamic>? applicationData;

  List<ApplicantDocument> documents = [];

  List<Map<String, dynamic>> notes = [];

  bool get hasApplication => applicationData != null;

  String get fullName =>
      (applicantData?['fullName'] ?? applicant?.name ?? 'Not available')
          .toString();

  String get cnic =>
      (applicantData?['cnic'] ?? applicant?.cnic ?? 'Not available').toString();

  String get phone =>
      (applicantData?['phone'] ??
          applicationData?['contactNumber'] ??
          applicant?.phone ??
          'Not available')
          .toString();

  String get email =>
      (applicantData?['email'] ?? applicant?.email ?? 'Not available')
          .toString();

  String get address =>
      (applicantData?['address'] ?? applicant?.address ?? 'Not available')
          .toString();

  String get city =>
      (applicantData?['city'] ?? 'Not available').toString();

  String get dateOfBirth =>
      _formatDateValue(applicantData?['dateOfBirth']);

  String get applicationId =>
      (applicationData?['ApplicationId'] ?? 'Not available').toString();

  String get applicationType =>
      (applicationData?['plotType'] ?? 'Not available').toString();

  String get serialNumber =>
      (applicationData?['serialNumber'] ?? 'Not available').toString();

  String get fee =>
      (applicationData?['fee'] ?? 'Not available').toString();

  String get applicationStatus =>
      (applicationData?['status'] ?? 'Not available').toString();

  String get appliedOn =>
      _formatDateValue(applicationData?['submittedAt']);

  String get profileCreatedOn =>
      _formatDateValue(applicantData?['createdAt']);

  @override
  Future<void> load() async {
    // We will call loadApplicant() instead.
  }

  Future<void> loadApplicant(Applicant selectedApplicant) async {
    isLoading = true;
    notifyListeners();

    applicant = selectedApplicant;

    try {
      // ---------------------------------------------------------
      // 1. Find applicant document using uid
      // ---------------------------------------------------------
      final applicantSnapshot = await _firestore
          .collection('applicants')
          .where('uid', isEqualTo: selectedApplicant.id)
          .limit(1)
          .get();

      if (applicantSnapshot.docs.isNotEmpty) {
        applicantData = applicantSnapshot.docs.first.data();
      }

      // ---------------------------------------------------------
      // 2. Find corresponding application
      // ---------------------------------------------------------
      if (selectedApplicant.id.isNotEmpty) {
        final applicationSnapshot = await _firestore
            .collection('applications')
            .where(
          'applicantId',
          isEqualTo: selectedApplicant.id,
        )
            .limit(1)
            .get();

        if (applicationSnapshot.docs.isNotEmpty) {
          applicationData = applicationSnapshot.docs.first.data();
        }
      }

      // ---------------------------------------------------------
      // 3. Documents
      // ---------------------------------------------------------
      //
      // Your current applicants/applications schema has no
      // document fields, so we deliberately keep this empty.
      //
      documents = [];

      // ---------------------------------------------------------
      // 4. Verification notes
      // ---------------------------------------------------------
      //
      // We will NOT read notes yet because there is currently
      // no notes collection/backend structure.
      //
      notes = [];
    } catch (e) {
      print('Error loading applicant details: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  // -------------------------------------------------------------
  // Verify / Reject
  // -------------------------------------------------------------

  Future<void> updateStatus(VerificationStatus status) async {
    if (applicationData == null || applicant == null) {
      return;
    }

    try {
      String firestoreStatus;

      switch (status) {
        case VerificationStatus.verified:
          firestoreStatus = 'Verified';
          break;

        case VerificationStatus.rejected:
          firestoreStatus = 'Rejected';
          break;

        default:
          firestoreStatus = 'Pending';
      }

      final applicationSnapshot = await _firestore
          .collection('applications')
          .where(
        'applicantId',
        isEqualTo: applicant!.id,
      )
          .limit(1)
          .get();

      if (applicationSnapshot.docs.isEmpty) {
        print('Application not found.');
        return;
      }

      await applicationSnapshot.docs.first.reference.update({
        'status': firestoreStatus,
      });

      applicant!.status = status;

      applicationData = {
        ...applicationData!,
        'status': firestoreStatus,
      };

      notifyListeners();
    } catch (e) {
      print('Error updating applicant status: $e');
    }
  }

  String _formatDateValue(dynamic value) {
    if (value == null) {
      return 'Not available';
    }

    if (value is Timestamp) {
      final date = value.toDate();

      return '${date.day.toString().padLeft(2, '0')} '
          '${_monthName(date.month)} '
          '${date.year}';
    }

    if (value is DateTime) {
      return '${value.day.toString().padLeft(2, '0')} '
          '${_monthName(value.month)} '
          '${value.year}';
    }

    final stringValue = value.toString().trim();

    if (stringValue.isEmpty) {
      return 'Not available';
    }

    return stringValue;
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
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

  // ── NEW: Plot Allocation Report state ──────────────────────────
  int totalPlots = 0;
  int availablePlots = 0;
  int bookedPlots = 0;
  int allocatedPlots = 0;

  final chartValues = const [
    65.0, 82.0, 44.0, 72.0, 91.0, 76.0, 88.0,
  ];

  List<ReportCardModel> get filteredReports {
    return reports.where((report) {
      final matchesQuery =
          query.isEmpty ||
              report.title.toLowerCase().contains(query) ||
              report.fileType.toLowerCase().contains(query);

      return matchesQuery;
    }).map((report) {
      return ReportCardModel(
        title: report.title,
        subtitle: report.subtitle,
        fileType: report.fileType,
        count: report.count,
        icon: _getIcon(report.fileType),
        color: _getColor(report.fileType),
      );
    }).toList();
  }

  IconData _getIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'excel':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'csv':
        return Icons.table_view_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  Color _getColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return AdminColors.rejected;
      case 'excel':
      case 'xlsx':
        return AdminColors.primary;
      case 'csv':
        return AdminColors.primary;
      default:
        return AdminColors.greyText;
    }
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
