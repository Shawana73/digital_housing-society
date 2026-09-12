import 'package:cloud_firestore/cloud_firestore.dart';

import '../../viewmodels/admin_view_models.dart';
import '../../models/admin_models.dart';
import '../../models/scheme_model.dart';

class BallotingViewModel extends BaseAdminViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  int get resultsDeclaredCount {
    return schemes
        .where(
          (scheme) =>
      scheme.status.trim().toLowerCase() == 'completed',
    )
        .length;
  }

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

  @override
  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      // =========================================================
      // 1. LOAD SCHEMES
      // =========================================================

      final schemesSnapshot =
      await _firestore.collection('schemes').get();

      schemes = schemesSnapshot.docs
          .map(
            (doc) => SchemeModel.fromMap(
          doc.data(),
          doc.id,
        ),
      )
          .toList();

      filteredSchemes = List.from(schemes);

      // =========================================================
      // 2. LOAD APPLICANTS
      // =========================================================

      final applicantsSnapshot =
      await _firestore.collection('applicants').get();

      totalApplicants = applicantsSnapshot.docs.length;

      // =========================================================
      // 3. LOAD APPLICATIONS
      // =========================================================

      final applicationsSnapshot =
      await _firestore.collection('applications').get();

      // =========================================================
      // 4. LOAD UPLOADS
      // =========================================================

      final uploadsSnapshot =
      await _firestore.collection('uploads').get();

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
      // 5. LOAD PAYMENTS
      // =========================================================

      final paymentsSnapshot =
      await _firestore.collection('payments').get();

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
      // 6. FIND APPROVED APPLICATIONS
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
      // 7. FIND OVERALL ELIGIBLE APPLICANTS
      // =========================================================

      final eligibleApplicants = approvedApplications
          .intersection(verifiedUploads)
          .intersection(verifiedPayments);

      verifiedApplicants = eligibleApplicants.length;

      // =========================================================
      // 8. SCHEME-WISE ELIGIBLE APPLICANTS
      // =========================================================

      eligibleApplicantsByScheme.clear();

      for (final scheme in schemes) {
        final schemeSize =
        _extractPlotSize(scheme.size);

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

          // Match application plot type with scheme size.
          if (applicationSize == schemeSize) {
            count++;
          }
        }

        eligibleApplicantsByScheme[
        scheme.documentId
        ] = count;
      }

      // =========================================================
      // 9. LOAD PLOTS
      // =========================================================

      final plotsSnapshot =
      await _firestore.collection('plots').get();

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

          return plotStatus == 'available' &&
              _extractPlotSize(plotSize) == schemeSize;
        }).length;

        availablePlotsByScheme[
        scheme.documentId
        ] = count;
      }

      // =========================================================
      // 11. LOAD CURRENT BALLOT CONFIG
      // =========================================================

      final ballotConfigDoc =
      await _firestore
          .collection('ballot_config')
          .doc('main')
          .get();

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

          case 'completed':
            status = BallotingLiveStatus.completed;
            break;

          case 'paused':
            status = BallotingLiveStatus.paused;
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
    } catch (e) {
      print(
        'ERROR LOADING BALLOTING DATA: $e',
      );
    }

    isLoading = false;
    notifyListeners();
  }

  void search(String query) {
    final value = query.trim().toLowerCase();

    if (value.isEmpty) {
      filteredSchemes = List.from(schemes);
    } else {
      filteredSchemes = schemes.where((scheme) {
        return scheme.name
            .toLowerCase()
            .contains(value) ||
            scheme.size
                .toLowerCase()
                .contains(value) ||
            scheme.status
                .toLowerCase()
                .contains(value);
      }).toList();
    }

    notifyListeners();
  }

  void clearSearch() {
    filteredSchemes = List.from(schemes);
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
}