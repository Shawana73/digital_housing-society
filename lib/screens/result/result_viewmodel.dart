import '../../models/admin_models.dart';
import '../../data/dummy_data.dart';
import '../../viewmodels/admin_view_models.dart'; // for BaseAdminViewModel

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