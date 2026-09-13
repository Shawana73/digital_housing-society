import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../models/admin_models.dart';
import '../../viewmodels/admin_view_models.dart';

class ResultViewModel extends BaseAdminViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<BallotingResult> results = [];

  String selectedFilter = 'All';

  // FIX (#2): track which scheme this screen is currently showing, so
  // results from different schemes never get mixed together.
  String? currentSchemeId;
  String? currentSchemeName;

  // FIX (#9): surfaced load errors instead of only printing them.
  String? errorMessage;

  List<String> get filters => [
    'All',
    'Selected',
    'Not Selected',
  ];

  List<BallotingResult> get filteredResults {
    return results.where((result) {
      final matchesQuery = query.isEmpty ||
          result.applicantName.toLowerCase().contains(query) ||
          result.cnic.toLowerCase().contains(query) ||
          result.plotNo.toLowerCase().contains(query) ||
          // FIX (#4): Application ID is now actually searchable, matching
          // the screen's search hint text.
          result.applicationId.toLowerCase().contains(query);

      final matchesFilter = selectedFilter == 'All' ||
          (selectedFilter == 'Selected' && result.selected) ||
          (selectedFilter == 'Not Selected' && !result.selected);

      return matchesQuery && matchesFilter;
    }).toList();
  }

  int get totalResults => results.length;

  int get selectedResults =>
      results.where((result) => result.selected).length;

  int get notSelectedResults =>
      results.where((result) => !result.selected).length;

  double get successRate {
    if (totalResults == 0) return 0;
    return (selectedResults / totalResults) * 100;
  }

  DateTime? get completionDate {
    final dated = results.where((r) => r.ballotingDate != null).toList();
    if (dated.isEmpty) return null;
    dated.sort((a, b) => b.ballotingDate!.compareTo(a.ballotingDate!));
    return dated.first.ballotingDate;
  }

  /// FIX (#2): load() now accepts an optional scheme filter. When a
  /// schemeId is provided (opened from a scheme's history card), only that
  /// scheme's results are fetched — preventing different schemes' winners
  /// from being mixed together, and keeping `completionDate` accurate.
  /// When schemeId is null (e.g. opened from the general FAB), all results
  /// are shown, preserving the previous "overview" behavior.
  @override
  Future<void> load({String? schemeId, String? schemeName}) async {
    isLoading = true;
    errorMessage = null;
    currentSchemeId = schemeId;
    currentSchemeName = schemeName;
    notifyListeners();

    try {
      Query<Map<String, dynamic>> resultsQuery =
      _firestore.collection('ballot_results');

      if (schemeId != null && schemeId.isNotEmpty) {
        resultsQuery = resultsQuery.where('schemeId', isEqualTo: schemeId);
      }

      final snapshot = await resultsQuery.get();

      results = snapshot.docs.map((doc) {
        final data = doc.data();

        return BallotingResult(
          applicantId: data['applicantId']?.toString() ?? doc.id,
          applicationId: data['applicationId']?.toString() ?? '',
          applicantName: data['fullName']?.toString() ?? '',
          cnic: data['cnic']?.toString() ?? '',
          plotNo: data['plotNumber']?.toString() ?? '',
          category: data['plotType']?.toString() ?? '',
          plotLocation: data['plotLocation']?.toString() ?? '',
          serialNumber: data['serialNumber']?.toString() ?? '',
          selected: data['isSelected'] == true,
          ballotingDate: data['ballotingDate'] is Timestamp
              ? (data['ballotingDate'] as Timestamp).toDate()
              : null,
        );
      }).toList();
    } catch (e) {
      debugPrint('ERROR LOADING BALLOT RESULTS: $e');
      errorMessage = 'Could not load results. Pull down to retry.';
    }

    isLoading = false;
    notifyListeners();
  }

  void setFilter(String value) {
    selectedFilter = value;
    notifyListeners();
  }

  /// FIX (#6 - security/missing feature): lightweight audit trail for
  /// exports of sensitive data (names + CNIC numbers). Records who
  /// exported, when, in what format, how many rows, and for which scheme.
  /// Failure to log never blocks the export itself — it's best-effort.
  Future<void> logExport({
    required String format,
    required int recordCount,
  }) async {
    try {
      await _firestore.collection('export_logs').add({
        'exportedBy': FirebaseAuth.instance.currentUser?.email ??
            FirebaseAuth.instance.currentUser?.uid ??
            'unknown',
        'exportedAt': Timestamp.now(),
        'format': format,
        'recordCount': recordCount,
        'schemeId': currentSchemeId ?? '',
        'schemeName': currentSchemeName ?? '',
      });
    } catch (e) {
      debugPrint('Failed to write export audit log: $e');
    }
  }
}