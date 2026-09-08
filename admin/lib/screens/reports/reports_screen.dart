import 'package:flutter/material.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_shell.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/premium_widgets.dart';
import 'reports_viewmodel.dart';
import 'reports_widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'package:excel/excel.dart' as xls;
import 'package:share_plus/share_plus.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportsViewModel _viewModel = ReportsViewModel();
  final TextEditingController _searchController = TextEditingController();
  String _trendPeriod = 'Monthly';

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_refresh);
    _viewModel.load();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_refresh);
    _viewModel.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2027),
      initialDateRange: DateTimeRange(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 28),
      ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: AdminColors.primary,
            onPrimary: AdminColors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      await _viewModel.setDateRange(picked);

      if (!mounted) return;

      showAdminSnack(
        context,
        'Date range updated successfully',
      );
    }
  }
  String _fmtDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${d.day.toString().padLeft(2, '0')} '
        '${months[d.month - 1]} ${d.year}';
  }
  List<(String, String)> _reportRows(String reportTitle) {
    final isPayment = reportTitle == 'Payment Report';
    final isApplicant = reportTitle == 'Applicant Summary';
    final isPlot = reportTitle == 'Plot Allocation Report';

    if (isPayment) {
      return [('Total Payments', _viewModel.totalPayments.toString())];
    }
    if (isApplicant) {
      return [
        ('Total Applicants', _viewModel.totalApplicants.toString()),
        ('Verified', _viewModel.verifiedApplicants.toString()),
        ('Pending', _viewModel.pendingApplicants.toString()),
        ('Rejected', _viewModel.rejectedApplicants.toString()),
      ];
    }
    if (isPlot) {
      return [
        ('Total Plots', _viewModel.totalPlots.toString()),
        ('Available', _viewModel.availablePlots.toString()),
        ('Booked', _viewModel.bookedPlots.toString()),
        ('Allocated', _viewModel.allocatedPlots.toString()),
      ];
    }
    return [('Total Records', _viewModel.totalApplicants.toString())];
  }
  void _openReportPreview(String reportTitle) {
    final rows = _reportRows(reportTitle);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AdminColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reportTitle,
                style: const TextStyle(
                  color: AdminColors.darkText,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              ...rows.map((r) => _reportInfoRow(r.$1, r.$2)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _exportReportPdf(reportTitle, rows);
                    },
                    icon: const Icon(Icons.picture_as_pdf_rounded, color: AdminColors.rejected),
                    label: const Text('Export PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminColors.rejected,
                      side: BorderSide(color: AdminColors.rejected.withOpacity(0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _exportReportExcel(reportTitle, rows);
                    },
                    icon: const Icon(Icons.table_chart_rounded),
                    label: const Text('Export Excel'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AdminColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportReportPdf(String reportTitle, List<(String, String)> rows) async {
    showAdminSnack(context, 'Generating PDF...');

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (pwContext) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(reportTitle, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text('Generated: ${DateTime.now().toString().split('.').first}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: ['Metric', 'Value'],
              data: rows.map((r) => [r.$1, r.$2]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            ),
          ],
        ),
      ),
    );

    try {
      await Printing.layoutPdf(
        onLayout: (format) async => doc.save(),
        name: '${reportTitle.replaceAll(' ', '_')}.pdf',
      );
      await _viewModel.saveReportRecord(
        title: reportTitle,
        subtitle: '${rows.first.$2} ${rows.first.$1}',
        fileType: 'PDF',
        count: int.tryParse(rows.first.$2.replaceAll(',', '')) ?? 0,
      );
    } catch (e) {
      if (mounted) showAdminSnack(context, 'PDF export failed: $e');
    }
  }

  Future<void> _exportReportExcel(String reportTitle, List<(String, String)> rows) async {
    showAdminSnack(context, 'Generating Excel...');

    final workbook = xls.Excel.createExcel();
    final sheet = workbook[reportTitle.length > 31 ? reportTitle.substring(0, 31) : reportTitle];
    workbook.setDefaultSheet(sheet.sheetName);

    sheet.appendRow([xls.TextCellValue('Metric'), xls.TextCellValue('Value')]);
    for (final r in rows) {
      sheet.appendRow([xls.TextCellValue(r.$1), xls.TextCellValue(r.$2)]);
    }

    final bytes = workbook.save();
    if (bytes == null) {
      if (mounted) showAdminSnack(context, 'Excel export failed');
      return;
    }

    try {
      await Share.shareXFiles([
        XFile.fromData(
          Uint8List.fromList(bytes),
          name: '${reportTitle.replaceAll(' ', '_')}.xlsx',
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ]);
      await _viewModel.saveReportRecord(
        title: reportTitle,
        subtitle: '${rows.first.$2} ${rows.first.$1}',
        fileType: 'XLSX',
        count: int.tryParse(rows.first.$2.replaceAll(',', '')) ?? 0,
      );
    } catch (e) {
      if (mounted) showAdminSnack(context, 'Excel export failed: $e');
    }
  }


  static const List<String> _allReportTitles = [
    'Applicant Summary',
    'Payment Report',
    'Balloting Report',
    'Plot Allocation Report',
  ];

  void _showExportSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_rounded, color: AdminColors.rejected),
                title: const Text('Export All as PDF'),
                subtitle: const Text('All 4 reports combined'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _exportAllPdf();
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart_rounded, color: AdminColors.success),
                title: const Text('Export All as Excel'),
                subtitle: const Text('Separate sheet per report'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _exportAllExcel();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportAllPdf() async {
    showAdminSnack(context, 'Generating combined PDF...');

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (pwContext) => [
          pw.Text('Digital Housing Society — All Reports',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text('Generated: ${DateTime.now().toString().split('.').first}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 16),
          for (final title in _allReportTitles) ...[
            pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: ['Metric', 'Value'],
              data: _reportRows(title).map((r) => [r.$1, r.$2]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            ),
            pw.SizedBox(height: 18),
          ],
        ],
      ),
    );

    try {
      await Printing.layoutPdf(
        onLayout: (format) async => doc.save(),
        name: 'all_reports.pdf',
      );
      await _viewModel.saveReportRecord(
        title: 'All Reports',
        subtitle: '${_allReportTitles.length} reports combined',
        fileType: 'PDF',
        count: _viewModel.totalApplicants,
      );
    } catch (e) {
      if (mounted) showAdminSnack(context, 'PDF export failed: $e');
    }
  }

  Future<void> _exportAllExcel() async {
    showAdminSnack(context, 'Generating combined Excel...');

    final workbook = xls.Excel.createExcel();
    var isFirstSheet = true;

    for (final title in _allReportTitles) {
      final sheetName = title.length > 31 ? title.substring(0, 31) : title;
      final sheet = workbook[sheetName];
      sheet.appendRow([xls.TextCellValue('Metric'), xls.TextCellValue('Value')]);
      for (final r in _reportRows(title)) {
        sheet.appendRow([xls.TextCellValue(r.$1), xls.TextCellValue(r.$2)]);
      }
      if (isFirstSheet) {
        workbook.setDefaultSheet(sheetName);
        isFirstSheet = false;
      }
    }

    if (workbook.sheets.containsKey('Sheet1') && workbook.sheets.length > 1) {
      workbook.delete('Sheet1');
    }

    final bytes = workbook.save();
    if (bytes == null) {
      if (mounted) showAdminSnack(context, 'Excel export failed');
      return;
    }

    try {
      await Share.shareXFiles([
        XFile.fromData(
          Uint8List.fromList(bytes),
          name: 'all_reports.xlsx',
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ]);
      await _viewModel.saveReportRecord(
        title: 'All Reports',
        subtitle: '${_allReportTitles.length} reports combined',
        fileType: 'XLSX',
        count: _viewModel.totalApplicants,
      );
    } catch (e) {
      if (mounted) showAdminSnack(context, 'Excel export failed: $e');
    }
  }

  Widget _reportInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AdminColors.greyText,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AdminColors.darkText,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _setTrendPeriod(String period) {
    setState(() => _trendPeriod = period);
    showAdminSnack(context, 'Trend period: $period');
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Reports',
      selectedIndex: 3,
      searchController: _searchController,
      searchHint: 'Search reports...',
      onSearchChanged: _viewModel.search,
      onSearchClear: () {
        _searchController.clear();
        _viewModel.clearSearch();
      },
      onFabTap: _showExportSheet,
      fabLabel: 'Export',
      fabIcon: Icons.file_download_rounded,
      isLoading: _viewModel.isLoading,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        children: [
          Row(children: [
            Expanded(child:DateRangeChip(
              label: _viewModel.selectedStartDate != null &&
                  _viewModel.selectedEndDate != null
                  ? '${_fmtDate(_viewModel.selectedStartDate!)} - '
                  '${_fmtDate(_viewModel.selectedEndDate!)}'
                  : 'All Dates',
              onTap: _pickDateRange,
            )),
          ]),
          const SizedBox(height: 16),
          const Text('Overview', style: TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: -.3)),
          const SizedBox(height: 12),
          ReportsStatsGrid(
            totalApplicants: _viewModel.totalApplicants,
            verifiedApplicants: _viewModel.verifiedApplicants,
            pendingApplicants: _viewModel.pendingApplicants,
            rejectedApplicants: _viewModel.rejectedApplicants,
          ),
          const SizedBox(height: 18),
          PremiumCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Expanded(
                    child: Text('Applicant Trend', style: TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                  PeriodDropdown(value: _trendPeriod, onChanged: _setTrendPeriod),
                  const SizedBox(width: 6),
                ]),
                const SizedBox(height: 6),
                const Row(children: [
                  LegendDot(color: AdminColors.primary, label: 'Total'),
                  SizedBox(width: 14),
                  LegendDot(color: AdminColors.success, label: 'Verified'),
                  SizedBox(width: 14),
                  LegendDot(color: AdminColors.rejected, label: 'Rejected'),
                ]),
                const SizedBox(height: 14),
                SizedBox(
                  height: 230,
                  child: TrendChart(
                    months: _viewModel.trendMonths,
                    total: _viewModel.totalTrend,
                    verified: _viewModel.verifiedTrend,
                    rejected: _viewModel.rejectedTrend,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(children: [
            const Expanded(
              child: Text('Quick Reports', style: TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: -.3)),
            ),
            GestureDetector(
              onTap: () => showAdminSnack(context, 'View all reports'),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('View All', style: TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w800, fontSize: 13)),
                SizedBox(width: 3),
                Icon(Icons.arrow_forward_rounded, color: AdminColors.primary, size: 16),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          QuickReportsGrid(
            onTap: (label) => _openReportPreview(label),
          ),
          const SizedBox(height: 22),
          const Text('Recent Reports', style: TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: -.3)),
          const SizedBox(height: 12),
          if (_viewModel.filteredReports.isEmpty)
            EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No reports found',
              subtitle: 'Try another search keyword.',
              buttonText: 'Reset',
              onPressed: () {
                _searchController.clear();
                _viewModel.clearSearch();
              },
            )
          else
            ..._viewModel.filteredReports.map((report) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
             child:RecentReportRow(
               report: report,
               onTap: () => _openReportPreview(report.title),
             ),
            ),
            ),
        ],
      ),
    );
  }
}