import 'package:flutter/material.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_shell.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/premium_widgets.dart';
import 'result_viewmodel.dart';
import 'result_widgets.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Balloting Result',
      selectedIndex: 2,
      searchController: _searchController,
      searchHint: 'Search by Application ID or Name...',
      onSearchChanged: _viewModel.search,
      onSearchClear: () {
        _searchController.clear();
        _viewModel.clearSearch();
      },
      onFabTap: () => showAdminSnack(context, 'Exporting results...'),
      fabLabel: 'Export',
      fabIcon: Icons.file_download_rounded,
      isLoading: _viewModel.isLoading,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        children: [
          const ResultCelebrationHero(),
          const SizedBox(height: 20),
          const ResultSLabel(text: 'Result Summary'),
          const SizedBox(height: 10),
          const ResultSummaryGrid(),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: AdminColors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: AdminColors.primary.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _viewModel.search,
                  style: const TextStyle(fontSize: 12.5, color: AdminColors.darkText, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    hintText: 'Search by Application ID or Name...',
                    prefixIcon: Icon(Icons.search_rounded, color: AdminColors.primary, size: 18),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: AdminColors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => showAdminSnack(context, 'Filter clicked'),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 46,
                  width: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: AdminColors.primary.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.tune_rounded, color: AdminColors.primary, size: 16),
                    SizedBox(width: 3),
                    Text('Filter', style: TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w800, fontSize: 10)),
                  ]),
                ),
              ),
            ),
          ]),
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
                boxShadow: [BoxShadow(color: AdminColors.primary.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  ..._viewModel.filteredResults.take(8).toList().asMap().entries.map((e) {
                    final index = e.key;
                    final result = e.value;
                    final isLast = index == (_viewModel.filteredResults.take(8).length - 1);
                    return WinnerRow(rank: index + 1, result: result, isLast: isLast);
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
                onTap: () => showAdminSnack(context, 'Viewing all winners'),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: AdminColors.primary.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6))],
                  ),
                  child: Row(children: [
                    Text('View All Winners (${_viewModel.filteredResults.length})',
                        style: const TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w800, fontSize: 13)),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded, color: AdminColors.primary, size: 20),
                  ]),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => showAdminSnack(context, 'Exporting PDF...'),
                icon: const Icon(Icons.picture_as_pdf_rounded, color: AdminColors.rejected),
                label: const Text('Export PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminColors.rejected,
                  side: BorderSide(color: AdminColors.rejected.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => showAdminSnack(context, 'Exporting Excel...'),
                icon: const Icon(Icons.table_chart_rounded),
                label: const Text('Export Excel'),
                style: FilledButton.styleFrom(
                  backgroundColor: AdminColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}