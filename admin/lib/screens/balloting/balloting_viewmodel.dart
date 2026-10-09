import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../viewmodels/admin_view_models.dart';
import '../../models/admin_models.dart';
import '../../models/scheme_model.dart';

class BallotingViewModel extends BaseAdminViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Real-time listeners
  final List<StreamSubscription> _subs = [];
  bool _initialized = false;
  String _searchText = '';

  // Latest snapshots of every collection used for the counts
  QuerySnapshot<Map<String, dynamic>>? _schemesSnap;
  QuerySnapshot<Map<String, dynamic>>? _applicantsSnap;
  QuerySnapshot<Map<String, dynamic>>? _applicationsSnap;
  QuerySnapshot<Map<String, dynamic>>? _uploadsSnap;
  QuerySnapshot<Map<String, dynamic>>? _paymentsSnap;
  QuerySnapshot<Map<String, dynamic>>? _priorWinnersSnap;
  QuerySnapshot<Map<String, dynamic>>? _plotsSnap;
  DocumentSnapshot<Map<String, dynamic>>? _configSnap;

  BallotingLiveStatus status = BallotingLiveStatus.ready;
  double progress = 0.0;

  int totalApplicants = 0;
  int verifiedApplicants = 0;
  int availablePlots = 0;

  int selectedApplications = 0;
  int notSelectedApplications = 0;

  String currentSchemeName = '';
  String currentSchemeSize = '';
  String currentBallotingStatus = 'Ready';

  List<SchemeModel> schemes = [];
  List<SchemeModel> filteredSchemes = [];

  // FIX (#9): surfaced load errors so the UI can show a retry banner
  // instead of silently showing an empty list.
  String? errorMessage;

  // Scheme-wise counts
  final Map<String, int> eligibleApplicantsByScheme = {};
  final Map<String, int> availablePlotsByScheme = {};

  List<SchemeModel> get upcomingSchemes {
    return filteredSchemes
        .where(
          (scheme) =>
      scheme.status.trim().toLowerCase() == 'to be run',
    )
        .toList();
  }

  List<SchemeModel> get completedSchemes {
    return filteredSchemes
        .where(
          (scheme) =>
      scheme.status.trim().toLowerCase() == 'completed',
    )
        .toList();
  }

  int get totalSchemes => schemes.length;

  int get upcomingCount {
    return schemes
        .where(
          (scheme) =>
      scheme.status.trim().toLowerCase() == 'to be run',
    )
        .length;
  }

  int get completedCount {
    return schemes
        .where(
          (scheme) =>
      scheme.status.trim().toLowerCase() == 'completed',
    )
        .length;
  }
  // Results are declared for every completed balloting,
  // so this is simply the same number as completedCount.
  int get resultsDeclaredCount => completedCount;

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

  // Extracts only the numeric Marla size.
  // Example:
  // "5 Marla Villa" -> "5"
  // "5 Marla"       -> "5"
  // "10 Marla Villa" -> "10"
  String _extractPlotSize(String value) {
    final match = RegExp(
      r'(\d+(?:\.\d+)?)\s*marla',
      caseSensitive: false,
    ).firstMatch(value);

    return match?.group(1)?.toLowerCase() ?? '';
  }

  int getEligibleApplicantsForScheme(SchemeModel scheme) {
    return eligibleApplicantsByScheme[scheme.documentId] ?? 0;
  }

  int getAvailablePlotsForScheme(SchemeModel scheme) {
    return availablePlotsByScheme[scheme.documentId] ?? 0;
  }

  // ------------------------------------------------------------
  // REAL-TIME LOADING
  // ------------------------------------------------------------

  Future<void> _cancelSubs() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }

  bool get _allReady =>
      _schemesSnap != null &&
          _applicantsSnap != null &&
          _applicationsSnap != null &&
          _uploadsSnap != null &&
          _paymentsSnap != null &&
          _priorWinnersSnap != null &&
          _plotsSnap != null &&
          _configSnap != null;

  void _listenQuery(
      Query<Map<String, dynamic>> query,
      void Function(QuerySnapshot<Map<String, dynamic>>) store,
      Completer<void> first, {
        bool isStats = true,
      }) {
    _subs.add(
      query.snapshots().listen(
            (snap) {
          store(snap);
          _rebuild(first, statsChanged: isStats, configChanged: false);
        },
        onError: (e) => _onError(e, first),
      ),
    );
  }

  void _onError(Object e, Completer<void> first) {
    debugPrint('ERROR LOADING BALLOTING DATA: $e');
    errorMessage = 'Could not load balloting data. Please tap Retry.';
    isLoading = false;
    notifyListeners();
    if (!first.isCompleted) first.complete();
  }

  void _rebuild(
      Completer<void> first, {
        required bool statsChanged,
        required bool configChanged,
      }) {
    // Pehle saari collections ka pehla data aane do, warna counts adhoore aate.
    if (!_allReady) return;

    try {
      if (!_initialized || statsChanged) _computeStats();
      if (!_initialized || configChanged) _applyConfig();
      _initialized = true;
      errorMessage = null;
    } catch (e) {
      debugPrint('ERROR LOADING BALLOTING DATA: $e');
      errorMessage = 'Could not load balloting data. Please tap Retry.';
    }

    isLoading = false;
    notifyListeners();
    if (!first.isCompleted) first.complete();
  }

  @override
  Future<void> load() async {
    await _cancelSubs();

    _schemesSnap = null;
    _applicantsSnap = null;
    _applicationsSnap = null;
    _uploadsSnap = null;
    _paymentsSnap = null;
    _priorWinnersSnap = null;
    _plotsSnap = null;
    _configSnap = null;
    _initialized = false;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final first = Completer<void>();

    _listenQuery(_firestore.collection('schemes'),
            (s) => _schemesSnap = s, first);
    _listenQuery(_firestore.collection('applicants'),
            (s) => _applicantsSnap = s, first);
    _listenQuery(_firestore.collection('applications'),
            (s) => _applicationsSnap = s, first);
    _listenQuery(_firestore.collection('uploads'),
            (s) => _uploadsSnap = s, first);
    _listenQuery(_firestore.collection('payments'),
            (s) => _paymentsSnap = s, first);
    _listenQuery(
        _firestore
            .collection('ballot_results')
            .where('isSelected', isEqualTo: true),
            (s) => _priorWinnersSnap = s,
        first);
    _listenQuery(_firestore.collection('plots'),
            (s) => _plotsSnap = s, first);

    _subs.add(
      _firestore.collection('ballot_config').doc('main').snapshots().listen(
            (doc) {
          _configSnap = doc;
          _rebuild(first, statsChanged: false, configChanged: true);
        },
        onError: (e) => _onError(e, first),
      ),
    );

    // Pehla data aane tak RefreshIndicator / spinner chalta rahe
    await first.future;
  }

  // ------------------------------------------------------------
  // COUNTS (pehle load() ke andar the, logic bilkul wahi)
  // ------------------------------------------------------------

  void _computeStats() {
    final schemesSnapshot = _schemesSnap!;
    final applicantsSnapshot = _applicantsSnap!;
    final applicationsSnapshot = _applicationsSnap!;
    final uploadsSnapshot = _uploadsSnap!;
    final paymentsSnapshot = _paymentsSnap!;
    final priorWinnersSnapshot = _priorWinnersSnap!;
    final plotsSnapshot = _plotsSnap!;

    // =========================================================
    // 1. SCHEMES
    // =========================================================

    schemes = schemesSnapshot.docs
        .map(
          (doc) => SchemeModel.fromMap(
        doc.data(),
        doc.id,
      ),
    )
        .toList();

    _applySearch();

    // =========================================================
    // 2. APPLICANTS
    // =========================================================

    totalApplicants = applicantsSnapshot.docs.length;

    // =========================================================
    // 4. UPLOADS
    // =========================================================

    final verifiedUploads = <String>{};

    for (final doc in uploadsSnapshot.docs) {
      final data = doc.data();

      final verificationStatus =
          data['verificationStatus']
              ?.toString()
              .trim()
              .toLowerCase() ??
              '';

      if (verificationStatus == 'verified') {
        final applicantId =
        data['applicantId']?.toString();

        if (applicantId != null &&
            applicantId.isNotEmpty) {
          verifiedUploads.add(applicantId);
        }
      }
    }

    // =========================================================
    // 5. PAYMENTS
    // =========================================================

    final verifiedPayments = <String>{};

    for (final doc in paymentsSnapshot.docs) {
      final data = doc.data();

      final paymentStatus =
          data['status']
              ?.toString()
              .trim()
              .toLowerCase() ??
              '';

      if (paymentStatus == 'verified') {
        final applicantId =
        data['applicantId']?.toString();

        if (applicantId != null &&
            applicantId.isNotEmpty) {
          verifiedPayments.add(applicantId);
        }
      }
    }

    // =========================================================
    // 6. APPROVED APPLICATIONS
    // =========================================================

    final approvedApplications = <String>{};

    for (final doc in applicationsSnapshot.docs) {
      final data = doc.data();

      final applicationStatus =
          data['status']
              ?.toString()
              .trim()
              .toLowerCase() ??
              '';

      if (applicationStatus == 'verified') {
        final applicantId =
        data['applicantId']?.toString();

        if (applicantId != null &&
            applicantId.isNotEmpty) {
          approvedApplications.add(applicantId);
        }
      }
    }

    // =========================================================
    // 7. OVERALL ELIGIBLE APPLICANTS
    // =========================================================

    final eligibleApplicants = approvedApplications
        .intersection(verifiedUploads)
        .intersection(verifiedPayments);

    verifiedApplicants = eligibleApplicants.length;

    // =========================================================
    // 8. SCHEME-WISE ELIGIBLE APPLICANTS
    // =========================================================

    eligibleApplicantsByScheme.clear();

    // FIX (bug — matches the balloting engine): builds a quick
    // applicantId -> CNIC lookup so this count can be deduplicated the
    // same way BallotingProcessingViewModel dedupes before shuffling.
    // Without this, a person with two applicant records (e.g. an
    // accidental duplicate registration) would be counted twice here,
    // showing an "Eligible" number on the scheme card that doesn't
    // match how many people can actually be drawn.
    final applicantCnicById = <String, String>{};
    for (final doc in applicantsSnapshot.docs) {
      final data = doc.data();
      applicantCnicById[doc.id] = (data['cnic']?.toString() ??
          data['cnicDigits']?.toString() ??
          '').trim();
    }

    // FIX (missing feature — real-world fairness rule): "one plot per
    // person, across the whole society" — so this card's count also
    // excludes anyone who has already won a plot in a previous
    // balloting for ANY scheme, matching the balloting engine's rule.
    final priorWinnerCnics = <String>{};
    for (final doc in priorWinnersSnapshot.docs) {
      final cnic = (doc.data()['cnic'] ?? '').toString().trim();
      if (cnic.isNotEmpty) {
        priorWinnerCnics.add(cnic);
      }
    }

    for (final scheme in schemes) {
      final schemeSize =
      _extractPlotSize(scheme.size);

      final seenCnics = <String>{};
      int count = 0;

      for (final doc in applicationsSnapshot.docs) {
        final data = doc.data();

        final applicantId =
            data['applicantId']?.toString() ?? '';

        // Applicant must already be fully eligible.
        if (!eligibleApplicants.contains(applicantId)) {
          continue;
        }

        final applicationPlotType =
            data['plotType']?.toString() ?? '';

        final applicationSize =
        _extractPlotSize(applicationPlotType);

        if (applicationPlotType.isNotEmpty &&
            applicationSize != schemeSize) {
          continue;
        }
        final cnic = applicantCnicById[applicantId] ?? '';

        if (cnic.isNotEmpty && priorWinnerCnics.contains(cnic)) {
          continue;
        }

        if (cnic.isEmpty || seenCnics.add(cnic)) {
          count++;
        }
      }

      eligibleApplicantsByScheme[
      scheme.documentId
      ] = count;
    }

    // =========================================================
    // 9. PLOTS
    // =========================================================

    // Overall available plots
    availablePlots = plotsSnapshot.docs.where((doc) {
      final data = doc.data();

      final plotStatus =
          data['status']
              ?.toString()
              .trim()
              .toLowerCase() ??
              '';

      return plotStatus == 'available';
    }).length;

    // =========================================================
    // 10. SCHEME-WISE AVAILABLE PLOTS
    // =========================================================

    availablePlotsByScheme.clear();

    for (final scheme in schemes) {
      final schemeSize =
      _extractPlotSize(scheme.size);

      final count = plotsSnapshot.docs.where((doc) {
        final data = doc.data();

        final plotStatus =
            data['status']
                ?.toString()
                .trim()
                .toLowerCase() ??
                '';

        final plotSize =
            data['plotSize']?.toString() ?? '';

        final plotSchemeId =
            data['schemeId']?.toString() ?? '';

        return plotStatus == 'available' &&
            plotSchemeId == scheme.documentId &&
            _extractPlotSize(plotSize) == schemeSize;
      }).length;

      availablePlotsByScheme[
      scheme.documentId
      ] = count;
    }
  }

  // =========================================================
  // 11. CURRENT BALLOT CONFIG
  // =========================================================

  void _applyConfig() {
    final ballotConfigDoc = _configSnap!;

    if (ballotConfigDoc.exists) {
      final data = ballotConfigDoc.data() ?? {};

      currentSchemeName =
          data['projectName']?.toString() ?? '';

      currentSchemeSize =
          data['block']?.toString() ?? '';

      currentBallotingStatus =
          data['status']?.toString() ?? 'Ready';

      selectedApplications =
          (data['selectedApplications'] as num?)
              ?.toInt() ??
              0;

      notSelectedApplications =
          (data['notSelectedApplications'] as num?)
              ?.toInt() ??
              0;

      progress =
          (data['progress'] as num?)
              ?.toDouble() ??
              0.0;

      switch (
      currentBallotingStatus.toLowerCase()) {
        case 'live':
          status = BallotingLiveStatus.running;
          break;

        case 'paused':
          status = BallotingLiveStatus.paused;
          break;

        case 'completed':
          status = BallotingLiveStatus.completed;
          break;

        case 'stopped':
          status = BallotingLiveStatus.stopped;
          break;

        default:
          status = BallotingLiveStatus.ready;
      }
    } else {
      selectedApplications = 0;
      notSelectedApplications = 0;
      progress = 0.0;

      currentSchemeName = '';
      currentSchemeSize = '';
      currentBallotingStatus = 'Ready';

      status = BallotingLiveStatus.ready;
    }
  }

  // ------------------------------------------------------------
  // SEARCH
  // ------------------------------------------------------------

  // Real-time update aane par bhi current search filter barqarar rahe.
  void _applySearch() {
    if (_searchText.isEmpty) {
      filteredSchemes = List.from(schemes);
    } else {
      filteredSchemes = schemes.where((scheme) {
        return scheme.name
            .toLowerCase()
            .contains(_searchText) ||
            scheme.size
                .toLowerCase()
                .contains(_searchText) ||
            scheme.status
                .toLowerCase()
                .contains(_searchText);
      }).toList();
    }
  }

  @override
  void search(String value) {
    _searchText = value.trim().toLowerCase();
    _applySearch();
    notifyListeners();
  }

  @override
  void clearSearch() {
    _searchText = '';
    _applySearch();
    notifyListeners();
  }

  void start() {
    status = BallotingLiveStatus.running;
    progress = 0.0;
    notifyListeners();
  }

  void pause() {
    status = BallotingLiveStatus.paused;
    notifyListeners();
  }

  void resume() {
    status = BallotingLiveStatus.running;
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

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    super.dispose();
  }
}