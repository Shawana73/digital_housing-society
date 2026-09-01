import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/plot_model.dart';
import '../../services/firestore_service.dart';

class AddPlotViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final plotId = TextEditingController();
  final plotSize = TextEditingController();
  final price = TextEditingController();
  final location = TextEditingController();
  final description = TextEditingController();

  Future<void> savePlot() async {
    final plot = PlotModel(
      documentId: '',
      plotId: plotId.text.trim(),
      plotSize: plotSize.text.trim(),
      price: double.tryParse(price.text.trim()) ?? 0,
      location: location.text.trim(),
      description: description.text.trim(),
      status: "Available",
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );

    await _firestoreService.addPlot(plot);
  }

  void reset() {
    plotId.clear();
    plotSize.clear();
    price.clear();
    location.clear();
    description.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    plotId.dispose();
    plotSize.dispose();
    price.dispose();
    location.dispose();
    description.dispose();
    super.dispose();
  }
}