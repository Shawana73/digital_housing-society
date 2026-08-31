import 'package:cloud_firestore/cloud_firestore.dart';

class PlotModel {
  const PlotModel({
    required this.id,
    required this.plotNumber,
    required this.plotType,
    required this.size,
    required this.location,
    required this.price,
    required this.status,
    required this.allocatedTo,
    this.block = '',
    this.phase = '',
    this.category = '',
    this.roadWidth = '',
    this.facing = '',
    this.dimensions = '',
    this.developmentPercent = 0,
    this.imageUrl = '',
    this.notes = '',
    this.featured = false,
  });

  final String id;
  final String plotNumber;
  final String plotType;
  final String size;
  final String location;
  final int price;
  final String status;
  final String allocatedTo;

  final String block;
  final String phase;
  final String category;
  final String roadWidth;
  final String facing;
  final String dimensions;
  final int developmentPercent;
  final String imageUrl;
  final String notes;
  final bool featured;

  factory PlotModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};

    int development = 0;
    final rawDevelopment =
        data['developmentPercent'] ?? data['developmentStatus'];
    if (rawDevelopment is num) {
      development = rawDevelopment.toInt().clamp(0, 100).toInt();
    } else {
      final match =
          RegExp(r'(\d{1,3})').firstMatch(rawDevelopment?.toString() ?? '');
      development =
          (int.tryParse(match?.group(1) ?? '') ?? 0).clamp(0, 100).toInt();
    }

    final category =
        (data['category'] ?? data['plotType'] ?? '').toString();
    final plotType =
        (data['plotType'] ?? data['category'] ?? '').toString();

    return PlotModel(
      id: doc.id,
      plotNumber: data['plotNumber']?.toString() ?? doc.id,
      plotType: plotType,
      size: data['size']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      price: (data['price'] as num?)?.toInt() ?? 0,
      status: data['status']?.toString() ?? 'Available',
      allocatedTo: data['allocatedTo']?.toString() ?? '',
      block: data['block']?.toString() ?? '',
      phase: data['phase']?.toString() ?? '',
      category: category,
      roadWidth: data['roadWidth']?.toString() ?? '',
      facing: data['facing']?.toString() ?? '',
      dimensions: data['dimensions']?.toString() ?? '',
      developmentPercent: development,
      imageUrl: data['imageUrl']?.toString() ?? '',
      notes: data['notes']?.toString() ?? '',
      featured: data['featured'] == true,
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
      'block': block,
      'phase': phase,
      'category': category,
      'roadWidth': roadWidth,
      'facing': facing,
      'dimensions': dimensions,
      'developmentPercent': developmentPercent,
      'imageUrl': imageUrl,
      'notes': notes,
      'featured': featured,
    };
  }
}
