import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../models/report_model.dart';
import '../../theme/admin_theme.dart';
import '../../viewmodels/admin_view_models.dart';

class ReportsViewModel extends BaseAdminViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ReportModel> reports = [];

  // Applicant statistics
  int totalApplicants = 0;
  int verifiedApplicants = 0;
  int pendingApplicants = 0;
  int rejectedApplicants = 0;
  int totalPayments = 0;
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  // Plot statistics
  int totalPlots = 0;
  int availablePlots = 0;
  int bookedPlots = 0;
  int allocatedPlots = 0;

  // Applicant trend
  final List<String> trendMonths = [];
  final List<double> totalTrend = [];
  final List<double> verifiedTrend = [];
  final List<double> rejectedTrend = [];

  // ------------------------------------------------------------
  // REPORTS
  // ------------------------------------------------------------

  List<ReportCardModel> get filteredReports {
    return reports.where((report) {
      return query.isEmpty ||
          report.title.toLowerCase().contains(query) ||
          report.subtitle.toLowerCase().contains(query);
    }).map((report) {
      return ReportCardModel(
        title: report.title,
        subtitle: report.subtitle,
        fileType: 'Report',
        count: report.count,
        icon: Icons.description_rounded,
        color: AdminColors.primary,
      );
    }).toList();
  }

  Future<void> setDateRange(DateTimeRange range) async {
    selectedStartDate = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );

    selectedEndDate = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
    );

    await load();
  }

  // ------------------------------------------------------------
  // LOAD ALL REPORT DATA
  // ------------------------------------------------------------

  @override
  Future<void> load() async {
    isLoading = true;
    notifyListeners();


    try {
      await Future.wait([
        _loadApplicants(),
        _loadPlots(),
        _loadPayments(),
      ]);

      _buildReports();
      await _buildApplicantTrend();
    } catch (e, stackTrace) {
      debugPrint('Error loading reports: $e');
      debugPrintStack(stackTrace: stackTrace);
    }

    isLoading = false;
    notifyListeners();
  }

  // ------------------------------------------------------------
  // APPLICANTS
  // ------------------------------------------------------------

  Future<void> _loadApplicants() async {
    try {
      Query<Map<String, dynamic>> queryRef =
      _firestore.collection('applicants');

      if (selectedStartDate != null && selectedEndDate != null) {
        queryRef = queryRef
            .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(
            selectedStartDate!,
          ),
        )
            .where(
          'createdAt',
          isLessThanOrEqualTo: Timestamp.fromDate(
            selectedEndDate!,
          ),
        );
      }

      final snapshot = await queryRef.get();

      totalApplicants = snapshot.docs.length;
      verifiedApplicants = 0;
      pendingApplicants = 0;
      rejectedApplicants = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final status = (data['profileStatus'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

        if (status == 'verified' || status == 'approved') {
          verifiedApplicants++;
        } else if (status == 'rejected') {
          rejectedApplicants++;
        } else {
          pendingApplicants++;
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading applicants for reports: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // ------------------------------------------------------------
  // PLOTS
  // ------------------------------------------------------------

  Future<void> _loadPlots() async {
    try {
      final snapshot =
      await _firestore.collection('plots').get();

      totalPlots = snapshot.docs.length;

      availablePlots = 0;
      bookedPlots = 0;
      allocatedPlots = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final status =
        (data['status'] ?? '').toString().trim().toLowerCase();

        switch (status) {
          case 'available':
            availablePlots++;
            break;

          case 'booked':
            bookedPlots++;
            break;

          case 'allocated':
            allocatedPlots++;
            break;
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading plots for reports: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
  Future<void> _loadPayments() async {
    try {
      Query<Map<String, dynamic>> queryRef =
      _firestore.collection('payments');

      if (selectedStartDate != null && selectedEndDate != null) {
        queryRef = queryRef
            .where(
          'submittedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(
            selectedStartDate!,
          ),
        )
            .where(
          'submittedAt',
          isLessThanOrEqualTo: Timestamp.fromDate(
            selectedEndDate!,
          ),
        );
      }

      final snapshot = await queryRef.get();

      totalPayments = snapshot.docs.length;
    } catch (e, stackTrace) {
      debugPrint('Error loading payments for reports: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // ------------------------------------------------------------
  // RECENT REPORTS
  // ------------------------------------------------------------

  void _buildReports() {
    final now = Timestamp.now();

    reports = [
      ReportModel(
        documentId: 'applicant-summary',
        title: 'Applicant Summary',
        subtitle: '$totalApplicants applicants',
        fileType: 'Report',
        count: totalApplicants,
        createdAt: now,
      ),

      ReportModel(
        documentId: 'payment-report',
        title: 'Payment Report',
        subtitle: '$totalPayments payments',
        fileType: 'Report',
        count: totalPayments,
        createdAt: now,
      ),

      ReportModel(
        documentId: 'balloting-report',
        title: 'Balloting Report',
        subtitle: 'Balloting and applicant statistics',
        fileType: 'Report',
        count: totalApplicants,
        createdAt: now,
      ),

      ReportModel(
        documentId: 'plot-allocation-report',
        title: 'Plot Allocation Report',
        subtitle: '$allocatedPlots allocated plots',
        fileType: 'Report',
        count: totalPlots,
        createdAt: now,
      ),
    ];
  }

  // ------------------------------------------------------------
  // APPLICANT TREND
  // ------------------------------------------------------------

  Future<void> _buildApplicantTrend() async {
    trendMonths.clear();
    totalTrend.clear();
    verifiedTrend.clear();
    rejectedTrend.clear();

    try {
      Query<Map<String, dynamic>> queryRef =
      _firestore.collection('applicants');

      if (selectedStartDate != null && selectedEndDate != null) {
        queryRef = queryRef
            .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(
            selectedStartDate!,
          ),
        )
            .where(
          'createdAt',
          isLessThanOrEqualTo: Timestamp.fromDate(
            selectedEndDate!,
          ),
        );
      }

      final snapshot = await queryRef.get();

      final Map<String, int> totalByMonth = {};
      final Map<String, int> verifiedByMonth = {};
      final Map<String, int> rejectedByMonth = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final createdAt = data['createdAt'];

        if (createdAt is! Timestamp) {
          continue;
        }

        final date = createdAt.toDate();

        final key = '${date.year}-${date.month}';

        totalByMonth[key] = (totalByMonth[key] ?? 0) + 1;

        final status = (data['profileStatus'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

        if (status == 'verified' || status == 'approved') {
          verifiedByMonth[key] = (verifiedByMonth[key] ?? 0) + 1;
        } else if (status == 'rejected') {
          rejectedByMonth[key] = (rejectedByMonth[key] ?? 0) + 1;
        }
      }

      final startDate = selectedStartDate ??
          DateTime(
            DateTime.now().year,
            DateTime.now().month - 5,
            1,
          );

      final endDate = selectedEndDate ?? DateTime.now();

      final startMonth = DateTime(
        startDate.year,
        startDate.month,
      );

      final endMonth = DateTime(
        endDate.year,
        endDate.month,
      );

      final monthNames = [
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

      DateTime current = startMonth;

      while (!current.isAfter(endMonth)) {
        final key = '${current.year}-${current.month}';

        trendMonths.add(monthNames[current.month - 1]);

        totalTrend.add(
          (totalByMonth[key] ?? 0).toDouble(),
        );

        verifiedTrend.add(
          (verifiedByMonth[key] ?? 0).toDouble(),
        );

        rejectedTrend.add(
          (rejectedByMonth[key] ?? 0).toDouble(),
        );

        current = DateTime(
          current.year,
          current.month + 1,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading applicant trend: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
  }