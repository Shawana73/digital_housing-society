import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../models/report_model.dart';
import '../../theme/admin_theme.dart';
import '../../viewmodels/admin_view_models.dart';

class ReportsViewModel extends BaseAdminViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Real-time listeners
  final List<StreamSubscription> _subs = [];

  // Latest applicants docs (trend isi se banta ha, dobara query nahi hoti)
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _applicantDocs = [];

  List<ReportModel> reports = [];

  // Applicant statistics
  int totalApplicants = 0;
  int verifiedApplicants = 0;
  int pendingApplicants = 0;
  int rejectedApplicants = 0;
  int totalPayments = 0;
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  int totalBallotEntries = 0;
  int ballotWinners = 0;
  int ballotNotSelected = 0;

  // Plot statistics
  int totalPlots = 0;
  int availablePlots = 0;
  int bookedPlots = 0;
  int allocatedPlots = 0;

  // Applicant trend
  final List<String> trendMonths = [];
  String trendPeriod = 'Monthly';
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

    await _saveDateRange();
    await load(); // naye date range ke saath listeners dobara lagte hain
  }
  Future<void> setTrendPeriod(String period) async {
    trendPeriod = period;
    await _buildApplicantTrend();
    notifyListeners();
  }
  Future<void> saveReportRecord({
    required String title,
    required String subtitle,
    required String fileType,
    required int count,
  }) async {
    try {
      await _firestore.collection('reports').add({
        'title': title,
        'subtitle': subtitle,
        'fileType': fileType,
        'count': count,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving report record: $e');
    }
  }
  Future<void> _loadSavedDateRange() async {
    try {
      final doc = await _firestore.collection('admin_settings').doc('reports_filter').get();
      if (doc.exists) {
        final data = doc.data()!;
        final start = data['startDate'];
        final end = data['endDate'];
        if (start is Timestamp && end is Timestamp) {
          selectedStartDate = start.toDate();
          selectedEndDate = end.toDate();
        }
      }
    } catch (e) {
      debugPrint('Error loading saved date range: $e');
    }
  }

  Future<void> _saveDateRange() async {
    try {
      await _firestore.collection('admin_settings').doc('reports_filter').set({
        if (selectedStartDate != null) 'startDate': Timestamp.fromDate(selectedStartDate!),
        if (selectedEndDate != null) 'endDate': Timestamp.fromDate(selectedEndDate!),
      });
    } catch (e) {
      debugPrint('Error saving date range: $e');
    }
  }

  // ------------------------------------------------------------
  // REAL-TIME HELPER
  // ------------------------------------------------------------

  // Query par listener lagata ha. Future pehla data (ya error) aane par
  // complete hota ha. Har naye snapshot par onData chalta ha aur UI update hoti ha.
  Future<void> _subscribe(
      Query<Map<String, dynamic>> queryRef,
      void Function(QuerySnapshot<Map<String, dynamic>>) onData,
      String label,
      ) {
    final first = Completer<void>();

    _subs.add(
      queryRef.snapshots().listen(
            (snapshot) {
          try {
            onData(snapshot);
          } catch (e, stackTrace) {
            debugPrint('Error loading $label for reports: $e');
            debugPrintStack(stackTrace: stackTrace);
          }
          notifyListeners();
          if (!first.isCompleted) first.complete();
        },
        onError: (e, stackTrace) {
          debugPrint('Error loading $label for reports: $e');
          if (!first.isCompleted) first.complete();
        },
      ),
    );

    return first.future;
  }

  Future<void> _cancelSubs() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }

  // ------------------------------------------------------------
  // LOAD ALL REPORT DATA
  // ------------------------------------------------------------

  @override
  Future<void> load() async {
    await _cancelSubs();

    isLoading = true;
    notifyListeners();

    if (selectedStartDate == null && selectedEndDate == null) {
      await _loadSavedDateRange();
    }

    try {
      await Future.wait([
        _loadApplicants(),
        _loadPlots(),
        _loadPayments(),
        _loadRecentReports(),
        _loadBallotingStats(),
      ]);
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

  Future<void> _loadApplicants() {
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

    return _subscribe(queryRef, (snapshot) {
      _applicantDocs = snapshot.docs;

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

      // Trend bhi isi snapshot se dobara banta ha
      _buildApplicantTrend();
    }, 'applicants');
  }

  // ------------------------------------------------------------
  // PLOTS
  // ------------------------------------------------------------

  Future<void> _loadPlots() {
    return _subscribe(_firestore.collection('plots'), (snapshot) {
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
    }, 'plots');
  }
  Future<void> _loadPayments() {
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

    return _subscribe(queryRef, (snapshot) {
      totalPayments = snapshot.docs.length;
    }, 'payments');
  }
  Future<void> _loadBallotingStats() {
    return _subscribe(_firestore.collection('ballot_results'), (snapshot) {
      totalBallotEntries = snapshot.docs.length;
      ballotWinners = 0;
      ballotNotSelected = 0;
      for (final doc in snapshot.docs) {
        final isSelected = doc.data()['isSelected'] == true;
        if (isSelected) {
          ballotWinners++;
        } else {
          ballotNotSelected++;
        }
      }
    }, 'balloting stats');
  }

  // ------------------------------------------------------------
  // RECENT REPORTS
  // ------------------------------------------------------------

  Future<void> _loadRecentReports() {
    final queryRef = _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .limit(20);

    return _subscribe(queryRef, (snapshot) {
      reports = snapshot.docs
          .map((doc) => ReportModel.fromMap(doc.data(), doc.id))
          .toList();
    }, 'recent reports');
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
      // Pehle yahan dobara applicants ki query hoti thi; ab latest
      // real-time snapshot (_applicantDocs) hi use hota ha.
      final docs = _applicantDocs;

      const monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];

      String bucketKey(DateTime date) {
        switch (trendPeriod) {
          case 'Daily':
            return '${date.year}-${date.month}-${date.day}';
          case 'Weekly':
            final weekOfYear =
            ((date.difference(DateTime(date.year, 1, 1)).inDays) / 7).floor();
            return '${date.year}-W$weekOfYear';
          default:
            return '${date.year}-${date.month}';
        }
      }

      String labelFor(DateTime date) {
        switch (trendPeriod) {
          case 'Daily':
            return '${date.day} ${monthNames[date.month - 1]}';
          case 'Weekly':
            final weekOfYear =
            ((date.difference(DateTime(date.year, 1, 1)).inDays) / 7).floor();
            return 'W$weekOfYear';
          default:
            return monthNames[date.month - 1];
        }
      }

      final Map<String, int> totalByKey = {};
      final Map<String, int> verifiedByKey = {};
      final Map<String, int> rejectedByKey = {};

      for (final doc in docs) {
        final data = doc.data();
        final createdAt = data['createdAt'];
        if (createdAt is! Timestamp) continue;

        final date = createdAt.toDate();
        final key = bucketKey(date);

        totalByKey[key] = (totalByKey[key] ?? 0) + 1;

        final status = (data['profileStatus'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

        if (status == 'verified' || status == 'approved') {
          verifiedByKey[key] = (verifiedByKey[key] ?? 0) + 1;
        } else if (status == 'rejected') {
          rejectedByKey[key] = (rejectedByKey[key] ?? 0) + 1;
        }
      }

      final startDate = selectedStartDate ??
          DateTime(DateTime.now().year, DateTime.now().month - 5, 1);
      final endDate = selectedEndDate ?? DateTime.now();

      DateTime current;
      DateTime end;
      DateTime Function(DateTime) advance;

      switch (trendPeriod) {
        case 'Daily':
          current = DateTime(startDate.year, startDate.month, startDate.day);
          end = DateTime(endDate.year, endDate.month, endDate.day);
          advance = (d) => d.add(const Duration(days: 1));
          break;
        case 'Weekly':
          current = DateTime(startDate.year, startDate.month, startDate.day);
          end = DateTime(endDate.year, endDate.month, endDate.day);
          advance = (d) => d.add(const Duration(days: 7));
          break;
        default:
          current = DateTime(startDate.year, startDate.month);
          end = DateTime(endDate.year, endDate.month);
          advance = (d) => DateTime(d.year, d.month + 1);
      }

      // Safety cap so a huge date range with Daily can't loop forever.
      var guard = 0;
      while (!current.isAfter(end) && guard < 400) {
        final key = bucketKey(current);

        trendMonths.add(labelFor(current));
        totalTrend.add((totalByKey[key] ?? 0).toDouble());
        verifiedTrend.add((verifiedByKey[key] ?? 0).toDouble());
        rejectedTrend.add((rejectedByKey[key] ?? 0).toDouble());

        current = advance(current);
        guard++;
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading applicant trend: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    super.dispose();
  }
}