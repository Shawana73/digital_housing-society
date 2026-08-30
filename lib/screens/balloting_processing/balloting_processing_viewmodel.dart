import 'package:flutter/material.dart';
import 'balloting_processing_widgets.dart'; // for ProcessingStep

class BallotingProcessingViewModel extends ChangeNotifier {
  double progress = 0.72;
  bool isRunning = true;
  bool isPaused = false;

  late List<ProcessingStep> steps = [
    const ProcessingStep(1, 'Initializing Balloting', 'Preparing system and data', completed: true),
    const ProcessingStep(2, 'Validating Eligible Applicants', 'Checking applicant eligibility', completed: true),
    const ProcessingStep(3, 'Shuffling Applicants Securely', 'Randomizing applicants list', completed: false, pending: true, inProgress: true),
    const ProcessingStep(4, 'Selecting Successful Applicants', 'Based on available plots', completed: false, pending: true),
    const ProcessingStep(5, 'Assigning Plot Numbers', 'Allocating plots to winners', completed: false, pending: true),
    const ProcessingStep(6, 'Finalizing Results', 'Saving results and updating status', completed: false, pending: true),
  ];

  String get statusLabel {
    if (isPaused) return 'Paused';
    if (isRunning) return 'Running...';
    if (progress == 0) return 'Stopped';
    return 'Ready';
  }

  void start() {
    isRunning = true;
    isPaused = false;
    progress = 0.72;
    notifyListeners();
  }

  void pause() {
    isPaused = true;
    isRunning = false;
    notifyListeners();
  }

  void resume() {
    isPaused = false;
    isRunning = true;
    notifyListeners();
  }

  void stop() {
    isRunning = false;
    isPaused = false;
    progress = 0.0;
    notifyListeners();
  }

  void complete() {
    progress = 1.0;
    isRunning = false;
    notifyListeners();
  }
}