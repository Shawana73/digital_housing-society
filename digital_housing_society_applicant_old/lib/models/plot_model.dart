import 'package:cloud_firestore/cloud_firestore.dart';

class PlotModel {
  final String id;
  final String plotNumber;
  final String plotType;
  final String size;
  final String location;
  final int price;
  final String status;
  final String allocatedTo;

  const PlotModel({
    required this.id,
    required this.plotNumber,
    required this.plotType,
    required this.size,
    required this.location,
    required this.price,
    required this.status,
    required this.allocatedTo,
  });

  factory PlotModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PlotModel(
      id: doc.id,
      plotNumber: data['plotNumber']?.toString() ?? doc.id,
      plotType: data['plotType']?.toString() ?? '',
      size: data['size']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      price: (data['price'] as num?)?.toInt() ?? 0,
      status: data['status']?.toString() ?? 'reserved',
      allocatedTo: data['allocatedTo']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plotNumber': plotNumber,
      'plotType': plotType,
      'size': size,
      'location': location,
      'price': price,
      'status': status,
      'allocatedTo': allocatedTo,
    };
  }
}
