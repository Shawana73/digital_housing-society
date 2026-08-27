import 'package:cloud_firestore/cloud_firestore.dart';

class ApplicantModel {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String cnic;
  final DateTime dateOfBirth;
  final String address;
  final String city;
  final DateTime createdAt;
  final String profileStatus;
  final bool notificationsEnabled;
  final bool ballotingRegistered;

  const ApplicantModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.cnic,
    required this.dateOfBirth,
    required this.address,
    required this.city,
    required this.createdAt,
    required this.profileStatus,
    this.notificationsEnabled = true,
    this.ballotingRegistered = false,
  });

  factory ApplicantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ApplicantModel(
      uid: data['uid']?.toString() ?? doc.id,
      fullName: data['fullName']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      cnic: data['cnic']?.toString() ?? '',
      dateOfBirth: _date(data['dateOfBirth']),
      address: data['address']?.toString() ?? '',
      city: data['city']?.toString() ?? '',
      createdAt: _date(data['createdAt']),
      profileStatus: data['profileStatus']?.toString() ?? 'active',
      notificationsEnabled: data['notificationsEnabled'] is bool ? data['notificationsEnabled'] as bool : true,
      ballotingRegistered: data['ballotingRegistered'] is bool ? data['ballotingRegistered'] as bool : false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'cnic': cnic,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'address': address,
      'city': city,
      'createdAt': Timestamp.fromDate(createdAt),
      'profileStatus': profileStatus,
      'notificationsEnabled': notificationsEnabled,
      'ballotingRegistered': ballotingRegistered,
    };
  }

  ApplicantModel copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? cnic,
    DateTime? dateOfBirth,
    String? address,
    String? city,
    DateTime? createdAt,
    String? profileStatus,
    bool? notificationsEnabled,
    bool? ballotingRegistered,
  }) {
    return ApplicantModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      cnic: cnic ?? this.cnic,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      city: city ?? this.city,
      createdAt: createdAt ?? this.createdAt,
      profileStatus: profileStatus ?? this.profileStatus,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      ballotingRegistered: ballotingRegistered ?? this.ballotingRegistered,
    );
  }

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
