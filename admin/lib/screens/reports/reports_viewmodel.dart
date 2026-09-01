import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../models/report_model.dart';
import '../../theme/admin_theme.dart';
import '../../viewmodels/admin_view_models.dart'; // for BaseAdminViewModel

class ReportsViewModel extends BaseAdminViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ReportModel> reports = [];

  int totalPlots = 0;
  int availablePlots = 0;
  int bookedPlots = 0;
  int allocatedPlots = 0;

  final chartValues = const [65.0, 82.0, 44.0, 72.0, 91.0, 76.0, 88.0];

  List<ReportCardModel> get filteredReports {
    return reports.where((report) {
      final matchesQuery = query.isEmpty ||
          report.title.toLowerCase().contains(query) ||
          report.fileType.toLowerCase().contains(query);
      return matchesQuery;
    }).map((report) {
      return ReportCardModel(
        title: report.title,
        subtitle: report.subtitle,
        fileType: report.fileType,
        count: report.count,
        icon: _getIcon(report.fileType),
        color: _getColor(report.fileType),
      );
    }).toList();
  }

  IconData _getIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'excel':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'csv':
        return Icons.table_view_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  Color _getColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return AdminColors.rejected;
      case 'excel':
      case 'xlsx':
        return AdminColors.primary;
      case 'csv':
        return AdminColors.primary;
      default:
        return AdminColors.greyText;
    }
  }

  @override
  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('reports').get();
      reports = snapshot.docs.map((doc) => ReportModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      debugPrint('Error loading reports: $e');
    }

    isLoading = false;
    notifyListeners();
  }
}