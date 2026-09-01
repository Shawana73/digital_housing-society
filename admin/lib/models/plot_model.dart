import 'package:cloud_firestore/cloud_firestore.dart';

class PlotModel {
  final String documentId;
  final String plotId;
  final String plotSize;
  final double price;
  final String location;
  final String description;
  final String status;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  PlotModel({
    required this.documentId,
    required this.plotId,
    required this.plotSize,
    required this.price,
    required this.location,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'plotId': plotId,
      'plotSize': plotSize,
      'price': price,
      'location': location,
      'description': description,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
  factory PlotModel.fromMap(
      Map<String, dynamic> map,
      String documentId,
      ) {
    return PlotModel(
      documentId: documentId,
      plotId: map['plotId'] ?? '',
      plotSize: map['plotSize'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'Available',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] ?? Timestamp.now(),
    );
  }
}