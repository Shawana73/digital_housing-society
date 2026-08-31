import '../../models/admin_models.dart';
import '../../data/dummy_data.dart';
import '../../viewmodels/admin_view_models.dart'; // for BaseAdminViewModel

class PaymentVerificationViewModel extends BaseAdminViewModel {
  final List<PaymentRecord> payments = DummyData.payments();
  String selectedFilter = 'All';

  List<String> get filters => ['All', 'Pending', 'Verified', 'Rejected'];

  List<PaymentRecord> get filteredPayments {
    return payments.where((payment) {
      final matchesQuery = query.isEmpty ||
          payment.applicantName.toLowerCase().contains(query) ||
          payment.transactionId.toLowerCase().contains(query) ||
          payment.amount.toLowerCase().contains(query);
      final matchesFilter = selectedFilter == 'All' || payment.status.label == selectedFilter;
      return matchesQuery && matchesFilter;
    }).toList();
  }

  void setFilter(String value) {
    selectedFilter = value;
    notifyListeners();
  }

  void approve(PaymentRecord payment) {
    payment.status = PaymentStatus.verified;
    notifyListeners();
  }

  void reject(PaymentRecord payment) {
    payment.status = PaymentStatus.rejected;
    notifyListeners();
  }
}