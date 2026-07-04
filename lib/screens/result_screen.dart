import 'package:flutter/material.dart';

import '../models/admin_models.dart';
import '../theme/admin_theme.dart';
import '../viewmodels/admin_view_models.dart';
import '../widgets/admin_shell.dart';
import '../widgets/app_snack.dart';
import '../widgets/premium_widgets.dart';

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
          // ── Completed celebration hero ─────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: AdminColors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: AdminColors.primary.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 10))],
            ),
            child: Column(children: [
              // Confetti dots decoration
              SizedBox(
                height: 120,
                child: Stack(alignment: Alignment.center, children: [
                  // Scattered colored dots
                  ..._confettiDots(),
                  // Green check circle
                  Container(
                    height: 82, width: 82,
                    decoration: BoxDecoration(
                      color: AdminColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AdminColors.success.withOpacity(0.30), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
                  ),
                ]),
              ),
              const SizedBox(height: 4),
              const Text('Balloting Completed!',
                  style: TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -.4)),
              const SizedBox(height: 6),
              const Text('10 Jul 2026, 11:02 AM',
                  style: TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Result Summary 2×2 grid ─────────────────────────────────
          const _SLabel(text: 'Result Summary'),
          const SizedBox(height: 10),
          _ResultSummaryGrid(),

          const SizedBox(height: 20),

          // ── Search + filter row ─────────────────────────────────────
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
                  height: 46, width: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: AdminColors.primary.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                    Icon(Icons.tune_rounded, color: AdminColors.primary, size: 16),
                    SizedBox(width: 3),
                    Text('Filter', style: TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w800, fontSize: 10)),
                  ]),
                ),
              ),
            ),
          ]),

          const SizedBox(height: 20),

          // ── Winners List ────────────────────────────────────────────
          const _SLabel(text: 'Winners List'),
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
                    return _WinnerRow(
                      rank: index + 1,
                      result: result,
                      isLast: isLast,
                    );
                  }),
                ],
              ),
            ),

          const SizedBox(height: 14),

          // ── View all winners ────────────────────────────────────────
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

          // ── Export buttons ──────────────────────────────────────────
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

  List<Widget> _confettiDots() {
    final colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.pink];
    const positions = [
      Offset(-80, -20), Offset(-65, 20), Offset(-90, 40),
      Offset(75, -25), Offset(85, 15), Offset(60, 45),
      Offset(-40, -38), Offset(40, -35), Offset(0, -45),
    ];
    return List.generate(positions.length, (i) {
      return Positioned(
        left: 80 + positions[i].dx,
        top: 20 + positions[i].dy,
        child: Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: colors[i % colors.length],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result summary 4-tile grid
// ─────────────────────────────────────────────────────────────────────────────

class _ResultSummaryGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tiles = [
      ('Total\nApplicants', '1,284', AdminColors.primary, Icons.groups_rounded),
      ('Successful',        '120',   AdminColors.success,  Icons.verified_rounded),
      ('Unsuccessful',      '1,164', AdminColors.rejected, Icons.cancel_rounded),
      ('Success\nRate',     '9.3%',  AdminColors.warning,  Icons.percent_rounded),
    ];

    return Row(children: tiles.asMap().entries.map((e) {
      final i = e.key;
      final (label, value, color, icon) = e.value;
      return Expanded(
        child: Container(
          margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AdminColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AdminColors.primary.withOpacity(0.07), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              height: 34, width: 34,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(height: 8),
            Text(label, maxLines: 2,
                style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 9.5, height: 1.2)),
            const SizedBox(height: 3),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: -.3)),
          ]),
        ),
      );
    }).toList());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Winner row
// ─────────────────────────────────────────────────────────────────────────────

class _WinnerRow extends StatelessWidget {
  final int rank;
  final BallotingResult result;
  final bool isLast;
  const _WinnerRow({required this.rank, required this.result, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          // Rank number
          Container(
            height: 28, width: 28,
            decoration: BoxDecoration(
              color: AdminColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(rank.toString().padLeft(2, '0'),
                  style: const TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w900, fontSize: 11)),
            ),
          ),
          const SizedBox(width: 10),
          // Name + ID
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(result.applicantName, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 2),
            Text(result.cnic, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 10.5)),
          ])),
          const SizedBox(width: 8),
          // Plot no
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('Plot No.', style: TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 9.5)),
            const SizedBox(height: 1),
            Text(result.plotNo, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w800, fontSize: 12)),
          ]),
          const SizedBox(width: 8),
          // Status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: result.selected ? AdminColors.success.withOpacity(0.12) : AdminColors.greyText.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              result.selected ? 'Successful' : 'Not Selected',
              style: TextStyle(
                  color: result.selected ? AdminColors.success : AdminColors.greyText,
                  fontWeight: FontWeight.w800,
                  fontSize: 9.5),
            ),
          ),
        ]),
      ),
      if (!isLast) Container(height: 1, color: AdminColors.border.withOpacity(0.6)),
    ]);
  }
}

class _SLabel extends StatelessWidget {
  final String text;
  const _SLabel({required this.text});

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: -.3));
}
