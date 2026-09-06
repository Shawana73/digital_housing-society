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
    final data =
        doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};

    // Admin side uses plotId.
    final plotId = data['plotId']?.toString() ?? doc.id;

    // Admin side uses plotSize.
    final plotSize = data['plotSize']?.toString() ??
        data['size']?.toString() ??
        '';

    // Admin side uses description.
    final description = data['description']?.toString() ??
        data['notes']?.toString() ??
        '';

    final rawPrice = data['price'];
    final price = rawPrice is num
        ? rawPrice.toInt()
        : int.tryParse(rawPrice?.toString() ?? '') ?? 0;

    final rawStatus = data['status']?.toString().trim().toLowerCase();

    // Keep status compatible with Admin.
    final status = switch (rawStatus) {
      'booked' => 'booked',
      'allocated' => 'allocated',
      'available' => 'available',
      'reserved' => 'booked',
      'sold' => 'allocated',
      _ => 'available',
    };

    // Derive block from IDs such as A-101, D-105, P-101.
    final derivedBlock = plotId.contains('-')
        ? plotId.split('-').first.trim().toUpperCase()
        : '';

    final block =
    data['block']?.toString().trim().isNotEmpty == true
        ? data['block'].toString().trim().toUpperCase()
        : derivedBlock;

    int development = 0;
    final rawDevelopment =
        data['developmentPercent'] ?? data['developmentStatus'];

    if (rawDevelopment is num) {
      development = rawDevelopment.toInt().clamp(0, 100).toInt();
    } else {
      final match = RegExp(r'(\d{1,3})')
          .firstMatch(rawDevelopment?.toString() ?? '');

      development =
          (int.tryParse(match?.group(1) ?? '') ?? 0)
              .clamp(0, 100)
              .toInt();
    }

    final plotType =
        data['plotType']?.toString() ??
            data['category']?.toString() ??
            '';

    final category =
        data['category']?.toString() ??
            data['plotType']?.toString() ??
            '';

    return PlotModel(
      id: plotId,
      plotNumber: plotId,
      plotType: plotType,
      size: plotSize,
      location: data['location']?.toString() ?? '',
      price: price,
      status: status,
      allocatedTo: data['allocatedTo']?.toString() ?? '',
      block: block,
      phase: data['phase']?.toString() ?? '',
      category: category,
      roadWidth: data['roadWidth']?.toString() ?? '',
      facing: data['facing']?.toString() ?? '',
      dimensions: data['dimensions']?.toString() ?? '',
      developmentPercent: development,
      imageUrl: data['imageUrl']?.toString() ?? '',
      notes: description,
      featured: data['featured'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plotId': id,
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