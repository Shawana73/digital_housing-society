import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/plot_model.dart';
import 'balloting_processing_widgets.dart';

class BallotingProcessingViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double progress = 0.0;
  int eligibleApplicantsCount = 0;
  int availablePlotsCount = 0;
  bool isRunning = false;
  bool isPaused = false;
  bool isProcessing = false;

  String? errorMessage;

  // FIX (missing feature — live transparency): every draw event (a winner
  // being selected + allocated a plot, or an applicant not selected) is
  // appended here as it happens, so the admin screen can show it live
  // instead of only a generic progress bar.
  final List<DrawFeedEntry> drawFeed = [];

  static List<ProcessingStep> _freshSteps() => [
    const ProcessingStep(
      1,
      'Initializing Balloting',
      'Preparing system and data',
      completed: false,
    ),
    const ProcessingStep(
      2,
      'Validating Eligible Applicants',
      'Checking applicant eligibility',
      completed: false,
    ),
    const ProcessingStep(
      3,
      'Shuffling Applicants Securely',
      'Randomizing applicants list',
      completed: false,
    ),
    const ProcessingStep(
      4,
      'Selecting Successful Applicants',
      'Based on available plots',
      completed: false,
    ),
    const ProcessingStep(
      5,
      'Assigning Plot Numbers',
      'Allocating plots to winners',
      completed: false,
    ),
    const ProcessingStep(
      6,
      'Finalizing Results',
      'Saving results and updating status',
      completed: false,
    ),
  ];

  List<ProcessingStep> steps = _freshSteps();

  String get statusLabel {
    if (isPaused) return 'Paused';
    if (isProcessing) return 'Running...';
    if (progress == 1.0) return 'Completed';
    if (progress == 0.0) return 'Ready';
    return 'Stopped';
  }

  String _maskCnic(String cnic) {
    final digits = cnic.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 13) return cnic.isEmpty ? '' : '•••••••••••';
    return 'XXXXX-XXXXXXX-${digits.substring(12, 13)}';
  }

  String _formatScheduledDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  // ============================================================
  // START BALLOTING
  // ============================================================

  Future<bool> start({
    String? schemeName,
    String? schemeSize,
    String? schemeId,
    // FIX (missing feature): the scheme's own balloting date. If provided
    // and it's still in the future, balloting is blocked from starting
    // early.
    DateTime? scheduledDate,
  }) async {
    if (isProcessing) return false;

    if (scheduledDate != null && DateTime.now().isBefore(scheduledDate)) {
      errorMessage =
      'This balloting is scheduled for ${_formatScheduledDate(scheduledDate)}. '
          'It cannot be started before that date.';
      return false;
    }

    // FIX (bug — re-run prevention): check the SCHEME's own document
    // status (not just the shared ballot_config doc, which only tracks
    // whichever run happened most recently and can't reliably represent
    // every individual scheme's history).
    if (schemeId != null && schemeId.isNotEmpty) {
      final schemeDoc =
      await _firestore.collection('schemes').doc(schemeId).get();

      final schemeStatus =
      schemeDoc.data()?['status']?.toString().trim().toLowerCase();

      if (schemeStatus == 'completed') {
        errorMessage =
        'Balloting for this scheme has already been completed and cannot be run again.';
        return false;
      }
    }

    final configSnapshot =
    await _firestore.collection('ballot_config').doc('main').get();

    final configData = configSnapshot.data();

    // FIX (bug): a run that throws partway through (e.g. "no eligible
    // applicants") used to leave ballot_config stuck on 'live' forever,
    // permanently blocking every future balloting attempt for every
    // scheme. Two safeguards now prevent that:
    //  1. Stale-lock auto-recovery — if the stuck run started more than
    //     30 minutes ago, it's treated as abandoned and ignored.
    //  2. The catch block below now resets ballot_config on failure (see
    //     further down), so this generally shouldn't happen going
    //     forward — this is just a safety net.
    final lockStartedAt = (configData?['startedAt'] as Timestamp?)?.toDate();
    final lockIsStale = lockStartedAt != null &&
        DateTime.now().difference(lockStartedAt) > const Duration(minutes: 30);

    // Guard against two different schemes being processed at the same
    // time (e.g. admin navigates away mid-run and starts another scheme).
    if ((configData?['status'] == 'live' ||
        configData?['status'] == 'paused') &&
        configData?['schemeId'] != null &&
        configData?['schemeId'] != schemeId &&
        !lockIsStale) {
      errorMessage =
      'Another balloting session is currently in progress. '
          'Please finish or stop it before starting a new one.';
      return false;
    }

    try {
      errorMessage = null;

      isProcessing = true;
      isRunning = true;
      isPaused = false;
      progress = 0.0;
      steps = _freshSteps();
      drawFeed.clear();

      // --------------------------------------------------------
      // STEP 1 - INITIALIZE
      // --------------------------------------------------------
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      final startedAt = Timestamp.now();
      _setStep(0, completed: true);
      progress = 0.10;
      notifyListeners();
      await _firestore.collection('ballot_config').doc('main').set({
        'status': 'live',
        'projectName': schemeName ?? 'Official Housing Balloting',
        'block': schemeSize ?? '',
        'schemeId': schemeId ?? '',
        'message': 'The official housing balloting draw is currently in progress.',
        'currentNumber': '0000',
        'liveFeed': [],
        'startedAt': startedAt,
        'sessionId': sessionId,
      }, SetOptions(merge: true));

      // --------------------------------------------------------
      // STEP 2 - GET ELIGIBLE APPLICANTS
      // --------------------------------------------------------

      final applicationsSnapshot =
      await _firestore.collection('applications').get();

      final uploadsSnapshot =
      await _firestore.collection('uploads').get();

      final paymentsSnapshot =
      await _firestore.collection('payments').get();

      // FIX (missing feature — real-world fairness rule): one plot per
      // person, across the WHOLE society, not just within one scheme.
      // Fetches every past winner (any scheme, any previous balloting)
      // and collects their CNICs, so they can be excluded below —
      // matching how real housing schemes run their draws.
      final priorWinnersSnapshot = await _firestore
          .collection('ballot_results')
          .where('isSelected', isEqualTo: true)
          .get();

      final priorWinnerCnics = <String>{};
      for (final doc in priorWinnersSnapshot.docs) {
        final cnic = (doc.data()['cnic'] ?? '').toString().trim();
        if (cnic.isNotEmpty) {
          priorWinnerCnics.add(cnic);
        }
      }

      // Verified document applicants
      final verifiedUploads = <String>{};

      for (final doc in uploadsSnapshot.docs) {
        final data = doc.data();

        final status = _normalize(data['verificationStatus']);

        if (status == 'verified') {
          final applicantId = data['applicantId']?.toString();

          if (applicantId != null && applicantId.isNotEmpty) {
            verifiedUploads.add(applicantId);
          }
        }
      }

      // Verified payment applicants
      final verifiedPayments = <String>{};

      for (final doc in paymentsSnapshot.docs) {
        final data = doc.data();

        final status = _normalize(data['status']);

        if (status == 'verified') {
          final applicantId = data['applicantId']?.toString();

          if (applicantId != null && applicantId.isNotEmpty) {
            verifiedPayments.add(applicantId);
          }
        }
      }

      // FIX (bug): this used to check for status == 'approved', but every
      // other part of the app (overview screen's eligible count, uploads,
      // payments, and the VerificationStatus enum itself: Pending /
      // Verified / Rejected) uses 'verified' as the reviewed-and-accepted
      // status. That mismatch meant the overview screen could show
      // "Eligible: 1" while the actual balloting engine found zero
      // eligible applicants and failed with "No eligible applicants
      // found" — now both use the same status value.
      final verifiedApplications =
      <String, Map<String, dynamic>>{};

      for (final doc in applicationsSnapshot.docs) {
        final data = doc.data();

        if (_normalize(data['status']) != 'verified') {
          continue;
        }

        final applicantId = data['applicantId']?.toString();

        if (applicantId == null || applicantId.isEmpty) {
          continue;
        }

        verifiedApplications[applicantId] = data;
      }

      // Final eligibility:
      // Approved application
      // + Verified documents
      // + Verified payment

      final eligibleApplicantIds = verifiedApplications.keys
          .where((id) {
        if (!verifiedUploads.contains(id) ||
            !verifiedPayments.contains(id)) {
          return false;
        }

        if (schemeSize == null || schemeSize.trim().isEmpty) {
          return true;
        }

        final application =
            verifiedApplications[id] ?? {};

        final applicationPlotType =
            application['plotType']?.toString() ?? '';

        if (applicationPlotType.isEmpty) {
          return true;
        }

        return _extractPlotSize(applicationPlotType) ==
            _extractPlotSize(schemeSize);
      })
          .toList();

      if (eligibleApplicantIds.isEmpty) {
        throw Exception(
          'No eligible applicants found. '
              'Application, documents and payment must all be verified.',
        );
      }
      await _firestore.collection('ballot_config').doc('main').set({
        'stage': 'validation',
        'progress': 0.25,
        'message': 'Validating eligible applicants...',
      }, SetOptions(merge: true));

      _setStep(1, completed: true);
      progress = 0.25;
      notifyListeners();

      // --------------------------------------------------------
      // GET APPLICANT DETAILS
      // --------------------------------------------------------

      final applicantSnapshots = await Future.wait(
        eligibleApplicantIds.map(
              (id) => _firestore
              .collection('applicants')
              .doc(id)
              .get(),
        ),
      );

      final applicants = <Map<String, dynamic>>[];

      for (var i = 0; i < eligibleApplicantIds.length; i++) {
        final applicantId = eligibleApplicantIds[i];

        final applicantDoc = applicantSnapshots[i];

        final applicantData =
            applicantDoc.data() ?? <String, dynamic>{};

        applicants.add({
          'applicantId': applicantId,
          'fullName':
          applicantData['fullName']?.toString() ?? '',
          'cnic':
          applicantData['cnic']?.toString() ??
              applicantData['cnicDigits']?.toString() ??
              '',
          'application':
          verifiedApplications[applicantId] ??
              <String, dynamic>{},
        });
      }

      // FIX (bug/missing feature — fairness): two safeguards before the
      // shuffle:
      //  1. Anyone who already won a plot in a PREVIOUS balloting (any
      //     scheme) is excluded entirely — "one plot per person" applied
      //     society-wide, the same rule real housing schemes use.
      //  2. Within this run, the same physical person can still end up
      //     with two different applicant/application records (e.g. an
      //     accidental duplicate registration) that both pass
      //     verification — those are deduplicated by CNIC so they're only
      //     entered once. An applicant with no CNIC on record is kept
      //     as-is rather than risk dropping a legitimate entry.
      final seenCnics = <String>{};
      final dedupedApplicants = <Map<String, dynamic>>[];

      for (final applicant in applicants) {
        final cnic = (applicant['cnic'] ?? '').toString().trim();

        if (cnic.isNotEmpty && priorWinnerCnics.contains(cnic)) {
          continue;
        }

        if (cnic.isEmpty || seenCnics.add(cnic)) {
          dedupedApplicants.add(applicant);
        }
      }

      applicants
        ..clear()
        ..addAll(dedupedApplicants);

      eligibleApplicantsCount = applicants.length;
      // --------------------------------------------------------
      // STEP 3 - GET AVAILABLE PLOTS
      // --------------------------------------------------------

      final plotsSnapshot =
      await _firestore.collection('plots').get();

      List<PlotModel> availablePlots = plotsSnapshot.docs
          .map(
            (doc) => PlotModel.fromMap(
          doc.data(),
          doc.id,
        ),
      )
          .where(
            (plot) =>
        _normalize(plot.status) == 'available',
      )
          .toList();

      // --------------------------------------------------------
      // FILTER BY SCHEME SIZE
      // --------------------------------------------------------

      if (schemeSize != null &&
          schemeSize.trim().isNotEmpty) {
        final requiredSize =
        _extractPlotSize(schemeSize);

        final matchingPlots = availablePlots.where((plot) {
          final plotSize =
          _extractPlotSize(plot.plotSize);

          return plotSize == requiredSize;
        }).toList();

        availablePlots = matchingPlots;
      }

      if (availablePlots.isEmpty) {
        throw Exception(
          'No available plots found for this balloting.',
        );
      }
      availablePlotsCount = availablePlots.length;

      // --------------------------------------------------------
      // STEP 3 - SECURE RANDOM SHUFFLE
      // --------------------------------------------------------

      final random = Random.secure();

      applicants.shuffle(random);
      availablePlots.shuffle(random);

      _setStep(2, completed: true);
      progress = 0.40;
      notifyListeners();
      await _firestore.collection('ballot_config').doc('main').set({
        'stage': 'shuffling',
        'progress': 0.40,
        'message': 'Applicants are being securely randomized...',
      }, SetOptions(merge: true));
      await Future.delayed(const Duration(seconds: 2));

      // --------------------------------------------------------
      // STEP 4 - SELECT WINNERS
      // --------------------------------------------------------

      final winnerCount = min(
        applicants.length,
        availablePlots.length,
      );
      await _firestore.collection('ballot_config').doc('main').set({
        'totalEligibleApplicants': applicants.length,
        'availablePlots': availablePlots.length,
        'selectedApplications': winnerCount,
        'stage': 'selecting',
        'progress': 0.55,
      }, SetOptions(merge: true));

      final winners =
      applicants.take(winnerCount).toList();

      final notSelected =
      applicants.skip(winnerCount).toList();

      _setStep(3, completed: true);
      progress = 0.55;
      notifyListeners();

      // --------------------------------------------------------
      // STEP 5 - ASSIGN PLOTS
      // --------------------------------------------------------

      final now = Timestamp.now();

      final results = <Map<String, dynamic>>[];

      var drawnCount = 0;

      for (var i = 0; i < winners.length; i++) {
        // PAUSE: soft-check — wait here (before starting the next winner)
        // until admin resumes. The winner currently being processed always
        // finishes first, since this check sits at the top of the loop.
        while (isPaused) {
          await Future.delayed(const Duration(milliseconds: 300));
        }

        // STOP: if admin stopped, exit the loop before drawing the next winner.
        if (!isProcessing) {
          break;
        }

        final applicant = winners[i];
        final plot = availablePlots[i];

        final drawNumber = i + 1;

        results.add({
          'applicantId': applicant['applicantId'],
          'applicationId':
          applicant['application']?['applicationId']?.toString() ?? '',
          'fullName': applicant['fullName'],
          'cnic': applicant['cnic'],
          'plotNumber': plot.plotId,
          'plotType': plot.plotSize,
          'plotLocation': plot.location,
          'isSelected': true,
          'serialNumber': '$drawNumber',
          'ballotingDate': now,
          'schemeName': schemeName ?? '',
          'schemeId': schemeId ?? '',
        });

        final drawProgress = winnerCount == 0
            ? 1.0
            : 0.55 + (0.45 * (drawNumber / winnerCount));

        // FIX (missing feature — live transparency): previously `progress`
        // (the local, UI-bound value) was only updated at big step
        // boundaries, so the admin's screen appeared frozen during the
        // actual draw. Now it updates — and notifyListeners() fires — on
        // every single draw, along with a new drawFeed entry showing
        // exactly who was drawn and which plot they got.
        progress = drawProgress;

        drawFeed.add(DrawFeedEntry(
          serial: drawNumber,
          applicantName: (applicant['fullName'] ?? '').toString(),
          cnicMasked: _maskCnic((applicant['cnic'] ?? '').toString()),
          plotNumber: plot.plotId,
          isSelected: true,
          time: DateTime.now(),
        ));

        notifyListeners();

        // Update current draw number for Applicant live screen
        await _firestore.collection('ballot_config').doc('main').set({
          'status': 'live',
          'currentNumber': drawNumber.toString().padLeft(4, '0'),
          'stage': 'selecting',
          'progress': drawProgress,
          'projectName': schemeName ?? 'Official Housing Balloting',
          'block': schemeSize ?? '',
          'schemeId': schemeId ?? '',
          'message': 'The official housing balloting draw is currently in progress.',
        }, SetOptions(merge: true));

        // Add this draw result to Applicant live feed
        await _firestore.collection('ballot_live_results').add({
          'applicationNumber':
          applicant['application']?['applicationId']?.toString() ?? '',
          'sessionId': sessionId,
          'schemeId': schemeId ?? '',
          'cnic': applicant['cnic'] ?? '',
          'plotNumber': plot.plotId,
          'text':
          'Draw #${drawNumber.toString().padLeft(4, '0')} completed - Plot ${plot.plotId} allocated.',
          'time': Timestamp.now(),
          'createdAt': Timestamp.now(),
        });

        drawnCount++;
        await Future.delayed(const Duration(seconds: 3));
      }

      // If the loop above broke early because of Stop, do NOT save any
      // ballot_results or allocate any plots — the draw is incomplete.
      // The partial ballot_live_results entries already written stay as
      // history (per the agreed behavior), and ballot_config is marked
      // 'stopped' so the applicant-facing live screen reflects it too.
      if (drawnCount < winners.length) {
        await _firestore.collection('ballot_config').doc('main').set({
          'status': 'stopped',
          'stage': 'stopped',
          'message': 'Balloting was stopped by admin before completion.',
        }, SetOptions(merge: true));

        isRunning = false;
        isPaused = false;
        isProcessing = false;
        errorMessage = 'Balloting was stopped before completion. No results were saved.';
        notifyListeners();

        return false;
      }

      // Not selected applicants — revealed in the live feed all at once,
      // right after the winner list is finalized (there's no meaningful
      // "one at a time" order for these, unlike winners).
      for (final applicant in notSelected) {
        results.add({
          'applicantId': applicant['applicantId'],
          'applicationId':
          applicant['application']?['applicationId']?.toString() ?? '',
          'fullName': applicant['fullName'],
          'cnic': applicant['cnic'],
          'plotNumber': '',
          'plotType': schemeSize ?? '',
          'plotLocation': '',
          'isSelected': false,
          'serialNumber': '',
          'ballotingDate': now,
          'schemeName': schemeName ?? '',
          'schemeId': schemeId ?? '',
        });

        drawFeed.add(DrawFeedEntry(
          serial: 0,
          applicantName: (applicant['fullName'] ?? '').toString(),
          cnicMasked: _maskCnic((applicant['cnic'] ?? '').toString()),
          plotNumber: null,
          isSelected: false,
          time: DateTime.now(),
        ));
      }
      notifyListeners();

      _setStep(4, completed: true);
      progress = 0.75;
      notifyListeners();

      // --------------------------------------------------------
      // STEP 6 - SAVE RESULTS
      // --------------------------------------------------------

      const chunkSize = 400;

      for (
      var start = 0;
      start < results.length;
      start += chunkSize
      ) {
        final end =
        min(start + chunkSize, results.length);

        final batch = _firestore.batch();

        for (var i = start; i < end; i++) {
          final result = results[i];

          final applicantId =
          result['applicantId'].toString();

          final resultRef = _firestore
              .collection('ballot_results')
              .doc('${schemeId ?? "unknown"}_$applicantId');

          batch.set(
            resultRef,
            result,
            SetOptions(merge: true),
          );
        }

        await batch.commit();
      }

      // --------------------------------------------------------
      // UPDATE WINNING PLOTS
      // --------------------------------------------------------

      for (
      var start = 0;
      start < winners.length;
      start += chunkSize
      ) {
        final end =
        min(start + chunkSize, winners.length);

        final batch = _firestore.batch();

        for (var i = start; i < end; i++) {
          final plot = availablePlots[i];

          batch.update(
            _firestore
                .collection('plots')
                .doc(plot.documentId),
            {
              'status': 'Allocated',
              'allocatedTo':
              winners[i]['applicantId'],
              'allocatedAt': now,
              'updatedAt': now,
            },
          );
        }

        await batch.commit();
      }

      // --------------------------------------------------------
      // COMPLETE
      // --------------------------------------------------------

      _setStep(5, completed: true);

      await _firestore.collection('ballot_config').doc('main').set({
        'status': 'completed',
        'projectName': schemeName ?? 'Official Housing Balloting',
        'block': schemeSize ?? '',
        'message': 'The official housing balloting draw has been completed.',
        'completedAt': Timestamp.now(),
        'totalEligibleApplicants': applicants.length,
        'totalEligibleApplications': applicants.length,
        'totalPlots': availablePlots.length,
        'availablePlots': availablePlots.length,
        'selectedApplications': winners.length,
        'notSelectedApplications': notSelected.length,
        'stage': 'completed',
        'progress': 1.0,
      }, SetOptions(merge: true));

      // FIX (bug — history move / re-run prevention): mark the SCHEME
      // itself as completed. BallotingViewModel splits "Upcoming" vs
      // "History" purely by scheme.status, so this single write is what
      // actually moves the scheme into Balloting History, and — combined
      // with the guard at the top of start() — stops it from ever being
      // run again.
      if (schemeId != null && schemeId.isNotEmpty) {
        await _firestore.collection('schemes').doc(schemeId).set({
          'status': 'Completed',
        }, SetOptions(merge: true));
      }

      progress = 1.0;
      isProcessing = false;
      isRunning = false;
      isPaused = false;

      notifyListeners();

      return true;
    } catch (e) {
      errorMessage = e.toString();

      isProcessing = false;
      isRunning = false;
      isPaused = false;

      notifyListeners();

      debugPrint(
        'BALLOTING ERROR: $e',
      );

      // FIX (bug): previously, if start() threw after ballot_config was
      // already marked 'live' (Step 1 sets this before any validation
      // that can fail), the doc stayed stuck on 'live' forever — blocking
      // every future balloting run. Now it's reset here so a failed run
      // doesn't lock out all future ones.
      try {
        await _firestore.collection('ballot_config').doc('main').set({
          'status': 'ready',
          'stage': 'error',
          'message': errorMessage,
        }, SetOptions(merge: true));
      } catch (_) {
        // Best-effort only — don't let a logging failure mask the
        // original error.
      }

      return false;
    }
  }

  // ============================================================
  // UI CONTROLS
  // ============================================================

  Future<void> pause() async {
    if (!isProcessing) return;

    isPaused = true;
    isRunning = false;

    notifyListeners();

    try {
      await _firestore.collection('ballot_config').doc('main').set({
        'status': 'paused',
        'stage': 'paused',
        'message': 'Balloting has been paused by the admin.',
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to sync paused state: $e');
    }
  }

  Future<void> resume() async {
    if (!isProcessing) return;

    isPaused = false;
    isRunning = true;

    notifyListeners();

    try {
      await _firestore.collection('ballot_config').doc('main').set({
        'status': 'live',
        'stage': 'selecting',
        'message': 'The official housing balloting draw is currently in progress.',
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to sync resumed state: $e');
    }
  }

  void stop() {
    if (!isProcessing) return;

    isProcessing = false;
    isRunning = false;
    isPaused = false;
    progress = 0.0;

    _resetSteps();

    notifyListeners();
  }

  void complete() {
    progress = 1.0;
    isProcessing = false;
    isRunning = false;
    isPaused = false;

    for (var i = 0; i < steps.length; i++) {
      _setStep(
        i,
        completed: true,
      );
    }

    notifyListeners();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _normalize(dynamic value) {
    return value
        ?.toString()
        .trim()
        .toLowerCase() ??
        '';
  }

  String _extractPlotSize(String value) {
    final normalized = value
        .trim()
        .toLowerCase();

    // "5 Marla Villa" -> "5 marla"
    // "5 Marla"       -> "5 marla"
    // "10 Marla Villa" -> "10 marla"

    final match = RegExp(
      r'(\d+(?:\.\d+)?)\s*marla',
      caseSensitive: false,
    ).firstMatch(normalized);

    if (match != null) {
      return '${match.group(1)} marla';
    }

    return normalized;
  }

  void _resetSteps() {
    steps = _freshSteps();
  }

  void _setStep(
      int index, {
        bool completed = false,
        bool inProgress = false,
        bool pending = false,
      }) {
    if (index < 0 || index >= steps.length) {
      return;
    }

    final old = steps[index];

    steps[index] = ProcessingStep(
      old.number,
      old.title,
      old.subtitle,
      completed: completed,
      inProgress: inProgress,
      pending: pending,
    );
  }
}