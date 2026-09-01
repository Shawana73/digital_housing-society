import '../../models/admin_models.dart';
import '../../data/dummy_data.dart';
import '../../viewmodels/admin_view_models.dart'; // for BaseAdminViewModel

class PlotVisualizationViewModel extends BaseAdminViewModel {
  final List<SocietyPlot> plots = DummyData.plots();
  double zoom = 1.0;

  List<SocietyPlot> get filteredPlots {
    if (query.isEmpty) return plots;
    return plots.where((p) => p.id.toLowerCase().contains(query) || p.location.toLowerCase().contains(query)).toList();
  }

  void zoomIn() {
    zoom = (zoom + 0.1).clamp(0.8, 1.5);
    notifyListeners();
  }

  void zoomOut() {
    zoom = (zoom - 0.1).clamp(0.8, 1.5);
    notifyListeners();
  }
}