import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String documentId;
  final String title;
  final String subtitle;
  final String fileType;
  final int count;
  final Timestamp createdAt;

  ReportModel({
    required this.documentId,
    required this.title,
    required this.subtitle,
    required this.fileType,
    required this.count,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'fileType': fileType,
      'count': count,
      'createdAt': createdAt,
    };
  }

  factory ReportModel.fromMap(
      Map<String, dynamic> map,
      String documentId,
      ) {
    return ReportModel(
      documentId: documentId,
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      fileType: map['fileType'] ?? '',
      count: (map['count'] ?? 0).toInt(),
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }
}