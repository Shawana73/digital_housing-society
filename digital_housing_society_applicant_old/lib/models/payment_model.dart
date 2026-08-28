import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String applicantId;
  final String applicationId;
  final int amount;
  final String plotType;
  final String paymentMethod;
  final String receiptUrl;
  final DateTime submittedAt;
  final String status;
  final String transactionId;

  const PaymentModel({
    required this.id,
    required this.applicantId,
    required this.applicationId,
    required this.amount,
    required this.plotType,
    required this.paymentMethod,
    required this.receiptUrl,
    required this.submittedAt,
    required this.status,
    required this.transactionId,
  });

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PaymentModel(
      id: doc.id,
      applicantId: data['applicantId']?.toString() ?? '',
      applicationId: data['applicationId']?.toString() ?? '',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      plotType: data['plotType']?.toString() ?? '',
      paymentMethod: data['paymentMethod']?.toString() ?? '',
      receiptUrl: data['receiptUrl']?.toString() ?? '',
      submittedAt: _date(data['submittedAt']),
      status: data['status']?.toString() ?? 'pending',
      transactionId: data['transactionId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'applicantId': applicantId,
      'applicationId': applicationId,
      'amount': amount,
      'plotType': plotType,
      'paymentMethod': paymentMethod,
      'receiptUrl': receiptUrl,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'status': status,
      'transactionId': transactionId,
    };
  }

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
