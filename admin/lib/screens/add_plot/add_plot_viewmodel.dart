import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/plot_model.dart';
import '../../models/scheme_model.dart';
import '../../services/firestore_service.dart';


class AddPlotViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final plotId = TextEditingController();
  final plotSize = TextEditingController();
  final price = TextEditingController();
  final location = TextEditingController();
  final description = TextEditingController();
  String? selectedSchemeId;
  List<SchemeModel> schemes = [];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _schemesSub;

  // Only schemes that are still "To Be Run" can receive new plots.
  void loadSchemes() {
    _schemesSub?.cancel();
    _schemesSub = FirebaseFirestore.instance
        .collection('schemes')
        .snapshots()
        .listen(
          (snapshot) {
        schemes = snapshot.docs
            .map((doc) => SchemeModel.fromMap(doc.data(), doc.id))
            .where((s) => s.status.trim().toLowerCase() == 'to be run')
            .toList();

        // Agar selected scheme ab list mai nahi rahi to selection saaf karein,
        // warna Dropdown assertion error deta ha.
        if (selectedSchemeId != null &&
            !schemes.any((s) => s.documentId == selectedSchemeId)) {
          selectedSchemeId = null;
        }
        notifyListeners();
      },
      onError: (e) {
        debugPrint('ERROR LOADING SCHEMES: $e');
      },
    );
  }

  void selectScheme(String? id) {
    selectedSchemeId = id;
    notifyListeners();
  }

  String _marla(String value) {
    final m = RegExp(r'(\d+(?:\.\d+)?)\s*marla', caseSensitive: false)
        .firstMatch(value);
    return m?.group(1) ?? '';
  }

  /// Returns null if OK, otherwise an error message. The plot's size must
  /// match the chosen scheme's size, otherwise balloting would never match
  /// this plot to that scheme's applicants.
  String? validateSchemeSize() {
    final match = schemes.where((s) => s.documentId == selectedSchemeId);
    if (match.isEmpty) return 'Please select a scheme';
    final scheme = match.first;
    final plotMarla = _marla(plotSize.text);
    if (plotMarla.isEmpty || plotMarla != _marla(scheme.size)) {
      return 'Plot size must match the scheme size (${scheme.size}), '
          'e.g. "5 Marla".';
    }
    return null;
  }


  Future<void> savePlot() async {
    final plot = PlotModel(
      documentId: '',
      plotId: plotId.text.trim(),
      plotSize: plotSize.text.trim(),
      price: double.parse(price.text.trim()),
      location: location.text.trim(),
      description: description.text.trim(),
      status: "Available",
      schemeId: selectedSchemeId ?? '',
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
    selectedSchemeId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _schemesSub?.cancel();
    plotId.dispose();
    plotSize.dispose();
    price.dispose();
    location.dispose();
    description.dispose();
    super.dispose();
  }
}