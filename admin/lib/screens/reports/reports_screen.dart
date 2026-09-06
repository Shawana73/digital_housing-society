import 'package:flutter/material.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_shell.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/premium_widgets.dart';
import 'reports_viewmodel.dart';
import 'reports_widgets.dart';

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
  void _openReportPreview(String reportTitle) {
    final isPayment = reportTitle == 'Payment Report';
    final isApplicant = reportTitle == 'Applicant Summary';
    final isPlot = reportTitle == 'Plot Allocation Report';

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

              if (isPayment)
                _reportInfoRow(
                  'Total Payments',
                  _viewModel.totalPayments.toString(),
                ),

              if (isApplicant) ...[
                _reportInfoRow(
                  'Total Applicants',
                  _viewModel.totalApplicants.toString(),
                ),
                _reportInfoRow(
                  'Verified',
                  _viewModel.verifiedApplicants.toString(),
                ),
                _reportInfoRow(
                  'Pending',
                  _viewModel.pendingApplicants.toString(),
                ),
                _reportInfoRow(
                  'Rejected',
                  _viewModel.rejectedApplicants.toString(),
                ),
              ],

              if (isPlot) ...[
                _reportInfoRow(
                  'Total Plots',
                  _viewModel.totalPlots.toString(),
                ),
                _reportInfoRow(
                  'Available',
                  _viewModel.availablePlots.toString(),
                ),
                _reportInfoRow(
                  'Booked',
                  _viewModel.bookedPlots.toString(),
                ),
                _reportInfoRow(
                  'Allocated',
                  _viewModel.allocatedPlots.toString(),
                ),
              ],

              if (!isPayment && !isApplicant && !isPlot)
                _reportInfoRow(
                  'Total Records',
                  _viewModel.totalApplicants.toString(),
                ),


            ],
          ),
        );
      },
    );
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