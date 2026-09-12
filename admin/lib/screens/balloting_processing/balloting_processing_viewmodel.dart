import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/plot_model.dart';
import 'balloting_processing_widgets.dart';

class BallotingProcessingViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double progress = 0.0;
  bool isRunning = false;
  bool isPaused = false;
  bool isProcessing = false;

  String? errorMessage;

  List<ProcessingStep> steps = [
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

  String get statusLabel {
    if (isPaused) return 'Paused';
    if (isProcessing) return 'Running...';
    if (progress == 1.0) return 'Completed';
    if (progress == 0.0) return 'Ready';
    return 'Stopped';
  }

  // ============================================================
  // START BALLOTING
  // ============================================================

  Future<bool> start({
    String? schemeName,
    String? schemeSize,
    String? schemeId,
  }) async {
    if (isProcessing) return false;
    final configSnapshot =
    await _firestore.collection('ballot_config').doc('main').get();

    final configData = configSnapshot.data();

    if (configData?['status'] == 'completed' &&
        configData?['schemeId'] == schemeId) {
      errorMessage =
      'Balloting for this scheme has already been completed.';
      return false;
    }

    try {
      errorMessage = null;

      isProcessing = true;
      isRunning = true;
      isPaused = false;
      progress = 0.0;

      void _resetSteps() {
        steps = [
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
      }

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

      // Approved applications
      final approvedApplications =
      <String, Map<String, dynamic>>{};

      for (final doc in applicationsSnapshot.docs) {
        final data = doc.data();

        if (_normalize(data['status']) != 'approved') {
          continue;
        }

        final applicantId = data['applicantId']?.toString();

        if (applicantId == null || applicantId.isEmpty) {
          continue;
        }

        approvedApplications[applicantId] = data;
      }
      debugPrint('APPROVED APPLICATIONS: $approvedApplications');
      debugPrint('VERIFIED UPLOADS: $verifiedUploads');
      debugPrint('VERIFIED PAYMENTS: $verifiedPayments');
      debugPrint('SCHEME SIZE: $schemeSize');
      // Final eligibility:
      // Approved application
      // + Verified documents
      // + Verified payment

      final eligibleApplicantIds = approvedApplications.keys
          .where((id) {
        if (!verifiedUploads.contains(id) ||
            !verifiedPayments.contains(id)) {
          return false;
        }

        if (schemeSize == null || schemeSize.trim().isEmpty) {
          return true;
        }

        final application =
            approvedApplications[id] ?? {};

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
          approvedApplications[applicantId] ??
              <String, dynamic>{},
        });
      }

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

      // Winners
      // Winners
      // Winners
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

      // Not selected applicants
      for (final applicant in notSelected) {
        results.add({
          'applicantId': applicant['applicantId'],
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
      }

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
              .doc(applicantId);

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

      return false;
    }
  }

  // ============================================================
  // UI CONTROLS
  // ============================================================

  void pause() {
    if (!isProcessing) return;

    isPaused = true;
    isRunning = false;

    notifyListeners();
  }

  void resume() {
    if (!isProcessing) return;

    isPaused = false;
    isRunning = true;

    notifyListeners();
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
    steps = [
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