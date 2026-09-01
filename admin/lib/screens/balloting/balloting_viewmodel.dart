import '../../viewmodels/admin_view_models.dart';// for BaseAdminViewModel
import '../../models/admin_models.dart';

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