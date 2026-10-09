import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/admin_models.dart';
import '../../viewmodels/admin_view_models.dart';

class DealerVerificationViewModel extends BaseAdminViewModel {
  final List<Dealer> dealers = [];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _dealersSub;

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
    // Purani listener band karein (refresh par dobara load() call hota ha)
    await _dealersSub?.cancel();

    isLoading = true;
    notifyListeners();

    final first = Completer<void>();

    _dealersSub = FirebaseFirestore.instance
        .collection('dealer_registrations')
        .snapshots()
        .listen(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
        try {
          dealers.clear();

          for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
            final data = doc.data();
            dealers.add(Dealer.fromFirestore(doc));
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
        if (!first.isCompleted) first.complete();
      },
      onError: (e) {
        debugPrint(
          'Error loading dealers: $e',
        );
        isLoading = false;
        notifyListeners();
        if (!first.isCompleted) first.complete();
      },
    );

    // Pehla data aane tak spinner / RefreshIndicator chalta rahe
    await first.future;
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

  Future<bool> approve(Dealer dealer) async {
    try {
      await FirebaseFirestore.instance
          .collection('dealer_registrations')
          .doc(dealer.id)
          .update({'verificationStatus': 'Approved'});

      dealer.status = VerificationStatus.verified;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error approving dealer: $e');
      return false;
    }
  }

  Future<bool> reject(Dealer dealer) async {
    try {
      await FirebaseFirestore.instance
          .collection('dealer_registrations')
          .doc(dealer.id)
          .update({'verificationStatus': 'Rejected'});

      dealer.status = VerificationStatus.rejected;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error rejecting dealer: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _dealersSub?.cancel();
    super.dispose();
  }
}