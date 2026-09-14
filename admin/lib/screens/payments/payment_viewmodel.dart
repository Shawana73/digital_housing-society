import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/admin_models.dart';
import '../../viewmodels/admin_view_models.dart';

class PaymentVerificationViewModel extends BaseAdminViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<PaymentRecord> payments = [];

  String selectedFilter = 'All';

  List<String> get filters => ['All', 'Pending', 'Verified', 'Rejected'];

  List<PaymentRecord> get filteredPayments {
    return payments.where((payment) {
      final matchesQuery = query.isEmpty ||
          payment.applicantName.toLowerCase().contains(query) ||
          payment.transactionId.toLowerCase().contains(query) ||
          payment.amount.toLowerCase().contains(query);

      final matchesFilter =
          selectedFilter == 'All' ||
              payment.status.label == selectedFilter;

      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  @override
  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      payments.clear();

      final paymentsSnapshot = await _firestore
          .collection('payments')
          .orderBy('submittedAt', descending: true)
          .get();

      // Load all applicants once and build a uid -> name map, instead of
      // running a separate Firestore query per payment (N+1 problem).
      final applicantsSnapshot = await _firestore.collection('applicants').get();
      final Map<String, String> nameByUid = {};
      for (final doc in applicantsSnapshot.docs) {
        final data = doc.data();
        final uid = data['uid']?.toString();
        if (uid != null && uid.isNotEmpty) {
          nameByUid[uid] = data['fullName']?.toString() ?? 'Unknown Applicant';
        }
      }

      for (final doc in paymentsSnapshot.docs) {
        final data = doc.data();
        final applicantId = data['applicantId']?.toString() ?? '';
        final applicantName = nameByUid[applicantId] ?? 'Unknown Applicant';

        payments.add(
          PaymentRecord(
            id: doc.id,
            applicantId: applicantId,
            applicantName: applicantName,
            transactionId:
            data['transactionId']?.toString() ?? 'Not available',
            amount: 'PKR ${data['amount'] ?? 0}',
            date: _formatDate(data['submittedAt']),
            method:
            data['paymentMethod']?.toString() ?? 'Not available',

            // Applicant-side schema mein separate receiptNo nahi hai.
            // Transaction ID ko receipt/reference ke taur par show kar rahe hain.
            receiptNo:
            data['transactionId']?.toString() ?? 'Not available',

            receiptUrl:
            data['receiptUrl']?.toString() ?? '',

            status: _mapStatus(data['status']),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading payments: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  PaymentStatus _mapStatus(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'verified':
      case 'approved':
        return PaymentStatus.verified;

      case 'rejected':
        return PaymentStatus.rejected;

      case 'submitted':
      case 'pending':
      default:
        return PaymentStatus.pending;
    }
  }

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      return '${date.day.toString().padLeft(2, '0')} '
          '${_monthName(date.month)} '
          '${date.year}';
    }

    return 'Not available';
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }

  void setFilter(String value) {
    selectedFilter = value;
    notifyListeners();
  }

  Future<void> approve(PaymentRecord payment) async {
    try {
      await _firestore.collection('payments').doc(payment.id).update({
        'status': 'verified',
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('activity_logs').add({
        'applicantId': payment.applicantId,
        'action': 'Payment verified',
        'description':
        'Admin verified the payment of ${payment.amount}.',
        'type': 'payment',
        'timestamp': FieldValue.serverTimestamp(),
      });

      payment.status = PaymentStatus.verified;
      notifyListeners();
    } catch (e) {
      debugPrint('Error approving payment: $e');
      rethrow;
    }
  }

  Future<void> reject(PaymentRecord payment) async {
    try {
      await _firestore.collection('payments').doc(payment.id).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('activity_logs').add({
        'applicantId': payment.applicantId,
        'action': 'Payment rejected',
        'description':
        'Admin rejected the payment of ${payment.amount}.',
        'type': 'payment',
        'timestamp': FieldValue.serverTimestamp(),
      });

      payment.status = PaymentStatus.rejected;
      notifyListeners();
    } catch (e) {
      debugPrint('Error rejecting payment: $e');
      rethrow;
    }
  }
}