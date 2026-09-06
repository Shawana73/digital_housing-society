import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/admin_models.dart';
import '../../viewmodels/admin_view_models.dart';

class PlotVisualizationViewModel extends BaseAdminViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<SocietyPlot> plots = [];
  double zoom = 1.0;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _plotsSubscription;

  @override
  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    await _plotsSubscription?.cancel();

    _plotsSubscription = _firestore.collection('plots').snapshots().listen(
          (snapshot) {
        plots = snapshot.docs.map((doc) {
          final data = doc.data();

          return SocietyPlot(
            id: data['plotId']?.toString() ?? doc.id,
            size: data['plotSize']?.toString() ?? '',
            location: data['location']?.toString() ?? '',
            price: data['price']?.toString() ?? '',
            description: data['description']?.toString() ?? '',
            status: _parsePlotStatus(data['status']),
          );
        }).toList();

        isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        plots = [];
        isLoading = false;
        notifyListeners();
      },
    );
  }

  PlotStatus _parsePlotStatus(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'booked':
        return PlotStatus.booked;

      case 'allocated':
        return PlotStatus.allocated;

      case 'available':
      default:
        return PlotStatus.available;
    }
  }

  List<SocietyPlot> get filteredPlots {
    if (query.isEmpty) {
      return plots;
    }

    return plots.where((p) {
      return p.id.toLowerCase().contains(query) ||
          p.location.toLowerCase().contains(query);
    }).toList();
  }

  void zoomIn() {
    zoom = (zoom + 0.1).clamp(0.8, 1.5);
    notifyListeners();
  }

  void zoomOut() {
    zoom = (zoom - 0.1).clamp(0.8, 1.5);
    notifyListeners();
  }
  void resetZoom() {
    zoom = 1.0;
    notifyListeners();
  }

  @override
  void dispose() {
    _plotsSubscription?.cancel();
    super.dispose();
  }
}