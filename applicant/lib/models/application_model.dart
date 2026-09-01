import 'package:cloud_firestore/cloud_firestore.dart';

class ApplicationModel {
  final String id;
  final String applicantId;
  final String fullName;
  final String cnic;
  final String plotType;
  final int fee;
  final String contactNumber;
  final String address;
  final String city;
  final String serialNumber;
  final DateTime submittedAt;
  final String status;

  const ApplicationModel({
    required this.id,
    required this.applicantId,
    required this.fullName,
    required this.cnic,
    required this.plotType,
    required this.fee,
    required this.contactNumber,
    required this.address,
    required this.city,
    required this.serialNumber,
    required this.submittedAt,
    required this.status,
  });

  factory ApplicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ApplicationModel(
      id: doc.id,
      applicantId: data['applicantId']?.toString() ?? '',
      fullName: data['fullName']?.toString() ?? '',
      cnic: data['cnic']?.toString() ?? '',
      plotType: data['plotType']?.toString() ?? '',
      fee: (data['fee'] as num?)?.toInt() ?? 0,
      contactNumber: data['contactNumber']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      city: data['city']?.toString() ?? '',
      serialNumber: data['serialNumber']?.toString() ?? '',
      submittedAt: _date(data['submittedAt']),
      status: data['status']?.toString() ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'applicantId': applicantId,
      'fullName': fullName,
      'cnic': cnic,
      'plotType': plotType,
      'fee': fee,
      'contactNumber': contactNumber,
      'address': address,
      'city': city,
      'serialNumber': serialNumber,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'status': status,
    };
  }

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
