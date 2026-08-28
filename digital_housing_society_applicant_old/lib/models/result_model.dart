import 'package:cloud_firestore/cloud_firestore.dart';

class ResultModel {
  final String id;
  final String applicantId;
  final String cnic;
  final String plotNumber;
  final String plotType;
  final String plotLocation;
  final bool isSelected;
  final DateTime ballotingDate;
  final String serialNumber;

  const ResultModel({
    required this.id,
    required this.applicantId,
    required this.cnic,
    required this.plotNumber,
    required this.plotType,
    required this.plotLocation,
    required this.isSelected,
    required this.ballotingDate,
    required this.serialNumber,
  });

  factory ResultModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ResultModel(
      id: doc.id,
      applicantId: data['applicantId']?.toString() ?? '',
      cnic: data['cnic']?.toString() ?? '',
      plotNumber: data['plotNumber']?.toString() ?? '',
      plotType: data['plotType']?.toString() ?? '',
      plotLocation: data['plotLocation']?.toString() ?? '',
      isSelected: data['isSelected'] is bool ? data['isSelected'] as bool : false,
      ballotingDate: _date(data['ballotingDate']),
      serialNumber: data['serialNumber']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'applicantId': applicantId,
      'cnic': cnic,
      'plotNumber': plotNumber,
      'plotType': plotType,
      'plotLocation': plotLocation,
      'isSelected': isSelected,
      'ballotingDate': Timestamp.fromDate(ballotingDate),
      'serialNumber': serialNumber,
    };
  }

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
