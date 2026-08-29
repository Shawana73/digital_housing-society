import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/plot_model.dart';
import '../../viewmodels/admin_view_models.dart'; // for BaseAdminViewModel

class PlotManagementViewModel extends BaseAdminViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<PlotModel> plots = [];
  String selectedFilter = 'All';

  List<String> get filters => ['All', 'Available', 'Booked', 'Allocated'];

  List<PlotModel> get filteredPlots {
    return plots.where((plot) {
      final matchesQuery = query.isEmpty ||
          plot.plotId.toLowerCase().contains(query) ||
          plot.plotSize.toLowerCase().contains(query) ||
          plot.location.toLowerCase().contains(query) ||
          plot.price.toString().contains(query);

      final matchesFilter = selectedFilter == 'All' ||
          plot.status.toLowerCase() == selectedFilter.toLowerCase();

      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('plots').get();
      plots = snapshot.docs.map((doc) => PlotModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      print('ERROR LOADING PLOTS: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  void setFilter(String value) {
    selectedFilter = value;
    notifyListeners();
  }

  Future<void> updateStatus(PlotModel plot, String status) async {
    try {
      await _firestore.collection('plots').doc(plot.documentId).update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });
      await load();
    } catch (e) {
      print('Error updating plot: $e');
    }
  }

  Future<void> deletePlot(PlotModel plot) async {
    try {
      await _firestore.collection('plots').doc(plot.documentId).delete();
      plots.removeWhere((item) => item.documentId == plot.documentId);
      notifyListeners();
    } catch (e) {
      print('Error deleting plot: $e');
    }
  }
}