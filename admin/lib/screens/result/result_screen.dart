import 'package:flutter/material.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_shell.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/premium_widgets.dart';
import 'result_viewmodel.dart';
import 'result_widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as xls;
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

class ResultScreen extends StatefulWidget {
  // FIX (#2): scheme-aware. When opened from a scheme's history card,
  // schemeId/schemeName are passed so only that scheme's results show.
  // When opened from the general "Results" FAB, both are null and all
  // schemes' results are shown (previous behavior).
  final String? schemeId;
  final String? schemeName;

  const ResultScreen({super.key, this.schemeId, this.schemeName});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final ResultViewModel _viewModel = ResultViewModel();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_refresh);
    _viewModel.load(
      schemeId: widget.schemeId,
      schemeName: widget.schemeName,
    );
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _reload() {
    return _viewModel.load(
      schemeId: widget.schemeId,
      schemeName: widget.schemeName,
    );
  }

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
                leading: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AdminColors.rejected,
                ),
                title: const Text('Export as PDF'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _exportPdf();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.table_chart_rounded,
                  color: AdminColors.success,
                ),
                title: const Text('Export as Excel'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _exportExcel();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // FIX (#3 - security): confirmation dialog shown before any export that
  // contains unmasked CNIC numbers, so admins can't accidentally share
  // sensitive data without realizing what's in the file.
  Future<bool> _confirmExport(String format) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AdminColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminColors.radius),
        ),
        title: const Text(
          'Export Sensitive Data?',
          style: TextStyle(
            color: AdminColors.darkText,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          'This $format file will contain applicants\' full names and '
              'unmasked CNIC numbers. Only share it through secure '
              'channels with authorized people.',
          style: const TextStyle(
            color: AdminColors.greyText,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AdminColors.primary),
            child: const Text('Export'),
          ),
        ],
      ),
    );

    return confirmed == true;
  }

  Future<void> _exportPdf() async {
    final data = _viewModel.filteredResults;

    if (data.isEmpty) {
      showAdminSnack(context, 'No results to export');
      return;
    }

    final confirmed = await _confirmExport('PDF');
    if (!confirmed) return;
    if (!mounted) return;

    showAdminSnack(context, 'Generating PDF...');

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        build: (pwContext) => [
          pw.Text(
            'Digital Housing Society — Balloting Result',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Generated: ${DateTime.now().toString().split('.').first}',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: [
              '#',
              'Name',
              'CNIC',
              'Plot No.',
              'Category',
              'Status',
            ],
            data: data.asMap().entries.map((e) {
              final i = e.key;
              final r = e.value;

              return [
                (i + 1).toString(),
                r.applicantName,
                r.cnic,
                r.plotNo,
                r.category,
                r.selected ? 'Successful' : 'Not Selected',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    try {
      await Printing.layoutPdf(
        onLayout: (format) async => doc.save(),
        name: 'balloting_result.pdf',
      );

      // FIX (#6): audit log entry, after a successful export.
      await _viewModel.logExport(format: 'PDF', recordCount: data.length);
    } catch (e) {
      if (mounted) {
        showAdminSnack(context, 'PDF export failed: $e');
      }
    }
  }

  Future<void> _exportExcel() async {
    final data = _viewModel.filteredResults;

    if (data.isEmpty) {
      showAdminSnack(context, 'No results to export');
      return;
    }

    final confirmed = await _confirmExport('Excel');
    if (!confirmed) return;
    if (!mounted) return;

    showAdminSnack(context, 'Generating Excel...');

    final workbook = xls.Excel.createExcel();
    final sheet = workbook['Balloting Result'];

    workbook.setDefaultSheet('Balloting Result');

    final headers = [
      '#',
      'Name',
      'CNIC',
      'Plot No.',
      'Category',
      'Status',
    ];

    sheet.appendRow(
      headers.map((h) => xls.TextCellValue(h)).toList(),
    );

    for (var i = 0; i < data.length; i++) {
      final r = data[i];

      sheet.appendRow([
        xls.IntCellValue(i + 1),
        xls.TextCellValue(r.applicantName),
        xls.TextCellValue(r.cnic),
        xls.TextCellValue(r.plotNo),
        xls.TextCellValue(r.category),
        xls.TextCellValue(
          r.selected ? 'Successful' : 'Not Selected',
        ),
      ]);
    }

    final bytes = workbook.save();

    if (bytes == null) {
      if (mounted) {
        showAdminSnack(context, 'Excel export failed');
      }
      return;
    }

    try {
      await Share.shareXFiles(
        [
          XFile.fromData(
            Uint8List.fromList(bytes),
            name: 'balloting_result.xlsx',
            mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
      );

      // FIX (#6): audit log entry, after a successful export.
      await _viewModel.logExport(format: 'Excel', recordCount: data.length);
    } catch (e) {
      if (mounted) {
        showAdminSnack(context, 'Excel export failed: $e');
      }
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _viewModel.filters.map((f) {
              final isActive = _viewModel.selectedFilter == f;

              return ListTile(
                title: Text(
                  f,
                  style: TextStyle(
                    fontWeight:
                    isActive ? FontWeight.w800 : FontWeight.w500,
                    color: isActive
                        ? AdminColors.primary
                        : AdminColors.darkText,
                  ),
                ),
                trailing: isActive
                    ? const Icon(
                  Icons.check_rounded,
                  color: AdminColors.primary,
                )
                    : null,
                onTap: () {
                  _viewModel.setFilter(f);
                  Navigator.pop(sheetContext);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.rejected.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.rejected.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AdminColors.rejected, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AdminColors.rejected, fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
          ),
          TextButton(
            onPressed: _reload,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _viewModel.removeListener(_refresh);
    _viewModel.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: widget.schemeName != null
          ? 'Result — ${widget.schemeName}'
          : 'Balloting Result',
      selectedIndex: 2,
      searchController: _searchController,
      searchHint: 'Search by Application ID or Name...',
      onSearchChanged: _viewModel.search,
      onSearchClear: () {
        _searchController.clear();
        _viewModel.clearSearch();
      },
      onFabTap: _showExportSheet,
      fabLabel: 'Export',
      fabIcon: Icons.file_download_rounded,
      isLoading: _viewModel.isLoading,
      onRefresh: _reload,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        children: [
          if (_viewModel.errorMessage != null)
            _buildErrorBanner(_viewModel.errorMessage!),
          ResultCelebrationHero(
            completionDate: _viewModel.completionDate,
          ),
          const SizedBox(height: 20),
          const ResultSLabel(text: 'Result Summary'),
          const SizedBox(height: 10),
          ResultSummaryGrid(
            total: _viewModel.totalResults,
            successful: _viewModel.selectedResults,
            unsuccessful: _viewModel.notSelectedResults,
            successRate: _viewModel.successRate,
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 20),
          // FIX (bug): this screen used to render its own extra search
          // TextField here — sharing the exact same controller as
          // AdminShell's top search bar — so there were two visually
          // separate search boxes doing the identical thing. The top one
          // (AdminShell, consistent with every other screen in the app)
          // is kept; only the Filter control stays here.
          Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: AdminColors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: _showFilterSheet,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color:
                        AdminColors.primary.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.tune_rounded,
                        color: AdminColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _viewModel.selectedFilter == 'All'
                            ? 'Filter'
                            : _viewModel.selectedFilter,
                        style: const TextStyle(
                          color: AdminColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const ResultSLabel(text: 'Winners List'),
          const SizedBox(height: 10),
          if (_viewModel.filteredResults.isEmpty)
            EmptyState(
              icon: Icons.emoji_events_outlined,
              title: 'No results found',
              subtitle: 'No result matches current search.',
              buttonText: 'Reset',
              onPressed: () {
                _searchController.clear();
                _viewModel.clearSearch();
                _viewModel.setFilter('All');
              },
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AdminColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AdminColors.primary.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ..._viewModel.filteredResults
                      .take(8)
                      .toList()
                      .asMap()
                      .entries
                      .map((e) {
                    final index = e.key;
                    final result = e.value;
                    final isLast = index ==
                        (_viewModel.filteredResults
                            .take(8)
                            .length -
                            1);

                    return WinnerRow(
                      rank: index + 1,
                      result: result,
                      isLast: isLast,
                    );
                  }),
                ],
              ),
            ),
          const SizedBox(height: 14),
          if (_viewModel.filteredResults.length > 8)
            Material(
              color: AdminColors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AllWinnersScreen(
                      results: _viewModel.filteredResults,
                    ),
                  ),
                ),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color:
                        AdminColors.primary.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        'View All Winners (${_viewModel.filteredResults.length})',
                        style: const TextStyle(
                          color: AdminColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AdminColors.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exportPdf,
                  icon: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: AdminColors.rejected,
                  ),
                  label: const Text('Export PDF'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminColors.rejected,
                    side: BorderSide(
                      color: AdminColors.rejected.withOpacity(0.4),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _exportExcel,
                  icon: const Icon(Icons.table_chart_rounded),
                  label: const Text('Export Excel'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AdminColors.success,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}