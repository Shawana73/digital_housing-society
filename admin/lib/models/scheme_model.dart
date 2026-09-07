import 'package:cloud_firestore/cloud_firestore.dart';

class SchemeModel {
  final String documentId;
  final String name;
  final String size;
  final Timestamp date;
  final String status;
  final String imagePath;

  SchemeModel({
    required this.documentId,
    required this.name,
    required this.size,
    required this.date,
    required this.status,
    required this.imagePath,
  });

  factory SchemeModel.fromMap(
      Map<String, dynamic> map,
      String documentId,
      ) {
    return SchemeModel(
      documentId: documentId,
      name: map['name']?.toString() ?? '',
      size: map['size']?.toString() ?? '',
      date: map['date'] is Timestamp
          ? map['date'] as Timestamp
          : Timestamp.now(),
      status: map['status']?.toString() ?? 'To Be Run',
      imagePath: map['imagePath']?.toString() ?? '',
    );
  }
}