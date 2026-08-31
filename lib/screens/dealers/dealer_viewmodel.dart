import '../../models/admin_models.dart';
import '../../data/dummy_data.dart';
import '../../viewmodels/admin_view_models.dart'; // for BaseAdminViewModel

class DealerVerificationViewModel extends BaseAdminViewModel {
  final List<Dealer> dealers = DummyData.dealers();
  String selectedFilter = 'All';

  List<String> get filters => ['All', 'Pending', 'Verified', 'Rejected'];

  List<Dealer> get filteredDealers {
    return dealers.where((dealer) {
      final matchesQuery = query.isEmpty ||
          dealer.name.toLowerCase().contains(query) ||
          dealer.cnic.toLowerCase().contains(query) ||
          dealer.phone.toLowerCase().contains(query) ||
          dealer.agency.toLowerCase().contains(query);
      final matchesFilter = selectedFilter == 'All' || dealer.status.label == selectedFilter;
      return matchesQuery && matchesFilter;
    }).toList();
  }

  void setFilter(String value) {
    selectedFilter = value;
    notifyListeners();
  }

  void approve(Dealer dealer) {
    dealer.status = VerificationStatus.verified;
    notifyListeners();
  }

  void reject(Dealer dealer) {
    dealer.status = VerificationStatus.rejected;
    notifyListeners();
  }
}