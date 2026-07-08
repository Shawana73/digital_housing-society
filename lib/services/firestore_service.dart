import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/plot_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get plotId => null;  //connection of firestore database

  Future<void> addPlot(PlotModel plot) async {
    try {
      final docRef = _firestore.collection('plots').doc(plot.plotId);

      final doc = await docRef.get();

      if (doc.exists) {
        throw Exception('Plot ID already exists');
      }

      await docRef.set(plot.toMap());

    } catch (e) {
      throw Exception('Failed to save plot: $e');
    }
  }
}