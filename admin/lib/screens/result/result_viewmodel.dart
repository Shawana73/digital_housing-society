import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/admin_models.dart';
import '../../viewmodels/admin_view_models.dart';

class ResultViewModel extends BaseAdminViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<BallotingResult> results = [];

  String selectedFilter = 'All';

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
          result.plotNo.toLowerCase().contains(query);

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

  @override
  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      final snapshot =
      await _firestore.collection('ballot_results').get();

      results = snapshot.docs.map((doc) {
        final data = doc.data();

        return BallotingResult(
          applicantName: data['fullName']?.toString() ?? '',
          cnic: data['cnic']?.toString() ?? '',
          plotNo: data['plotNumber']?.toString() ?? '',
          category: data['plotType']?.toString() ?? '',
          selected: data['isSelected'] == true,
        );
      }).toList();
    } catch (e) {
      print('ERROR LOADING BALLOT RESULTS: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  void setFilter(String value) {
    selectedFilter = value;
    notifyListeners();
  }
}