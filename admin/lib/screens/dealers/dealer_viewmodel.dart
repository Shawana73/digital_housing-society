import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/admin_models.dart';
import '../../viewModels/admin_view_models.dart';

class DealerVerificationViewModel extends BaseAdminViewModel {
  final List<Dealer> dealers = [];

  String selectedFilter = 'All';

  List<String> get filters {
    return [
      'All',
      'Pending',
      'Verified',
      'Rejected',
    ];
  }

  List<Dealer> get filteredDealers {
    return dealers.where((dealer) {
      final String searchQuery = query.toLowerCase();

      final bool matchesQuery =
          searchQuery.isEmpty ||
              dealer.name.toLowerCase().contains(searchQuery) ||
              dealer.cnic.toLowerCase().contains(searchQuery) ||
              dealer.phone.toLowerCase().contains(searchQuery) ||
              dealer.agency.toLowerCase().contains(searchQuery);

      final bool matchesFilter =
          selectedFilter == 'All' ||
              dealer.status.label == selectedFilter;

      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
      await FirebaseFirestore.instance
          .collection('dealer_registrations')
          .get();

      dealers.clear();

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
      in snapshot.docs) {
        final data = doc.data();

        dealers.add(
          Dealer(
            id: doc.id,
            name: data['fullName']?.toString() ?? '',
            cnic: data['cnic']?.toString() ?? '',
            phone: data['phone']?.toString() ?? '',
            agency: data['companyName']?.toString() ?? '',
            city: data['city']?.toString() ?? '',
            status: _getStatus(
              data['verificationStatus']?.toString(),
            ),
          ),
        );
      }

      debugPrint(
        'Loaded ${dealers.length} dealers from Firestore',
      );
    } catch (e) {
      debugPrint(
        'Error loading dealers: $e',
      );
    }

    isLoading = false;
    notifyListeners();
  }

  VerificationStatus _getStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
      case 'verified':
        return VerificationStatus.verified;

      case 'rejected':
        return VerificationStatus.rejected;

      case 'pending':
      default:
        return VerificationStatus.pending;
    }
  }

  void setFilter(String value) {
    selectedFilter = value;
    notifyListeners();
  }

  Future<void> approve(Dealer dealer) async {
    try {
      await FirebaseFirestore.instance
          .collection('dealer_registrations')
          .doc(dealer.id)
          .update({
        'verificationStatus': 'Approved',
      });

      dealer.status = VerificationStatus.verified;

      notifyListeners();

      debugPrint(
        'Dealer ${dealer.id} approved',
      );
    } catch (e) {
      debugPrint(
        'Error approving dealer: $e',
      );
    }
  }

  Future<void> reject(Dealer dealer) async {
    try {
      await FirebaseFirestore.instance
          .collection('dealer_registrations')
          .doc(dealer.id)
          .update({
        'verificationStatus': 'Rejected',
      });

      dealer.status = VerificationStatus.rejected;

      notifyListeners();

      debugPrint(
        'Dealer ${dealer.id} rejected',
      );
    } catch (e) {
      debugPrint(
        'Error rejecting dealer: $e',
      );
    }
  }
}