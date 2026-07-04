import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../models/admin_models.dart';
import '../theme/admin_theme.dart';
import '../viewmodels/admin_view_models.dart';
import '../widgets/admin_shell.dart';
import '../widgets/app_snack.dart';
import '../widgets/premium_widgets.dart';

class PlotManagementScreen extends StatefulWidget {
  const PlotManagementScreen({super.key});

  @override
  State<PlotManagementScreen> createState() => _PlotManagementScreenState();
}

class _PlotManagementScreenState extends State<PlotManagementScreen> {
  final PlotManagementViewModel _viewModel = PlotManagementViewModel();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_refresh);
    _viewModel.load();
  }

  void _refresh() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    _viewModel.removeListener(_refresh);
    _viewModel.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openEditSheet(SocietyPlot plot) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AdminColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SectionHeader(title: 'Edit ${plot.id}', subtitle: 'Change local plot status'),
            ...PlotStatus.values.map((status) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PremiumCard(
                    onTap: () {
                      Navigator.pop(context);
                      _viewModel.updateStatus(plot, status);
                      showAdminSnack(context, '${plot.id} marked ${status.label}');
                    },
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      GradientIconBox(icon: Icons.circle_rounded, color: status.color),
                      const SizedBox(width: 12),
                      Expanded(child: Text(status.label, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900))),
                      if (plot.status == status) const Icon(Icons.check_circle_rounded, color: AdminColors.primary),
                    ]),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePlot(SocietyPlot plot) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminColors.radius)),
        title: Text('Delete ${plot.id}?'),
        content: const Text('This will remove the plot from local dummy list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      _viewModel.deletePlot(plot);
      if (mounted) showAdminSnack(context, '${plot.id} deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Plot Management',
      selectedIndex: 0,
      searchController: _searchController,
      searchHint: 'Search plots, size, location...',
      onSearchChanged: _viewModel.search,
      onSearchClear: () { _searchController.clear(); _viewModel.clearSearch(); },
      onFabTap: () => Navigator.pushNamed(context, AdminRoutes.addPlot),
      fabLabel: 'Add Plot',
      fabIcon: Icons.add_home_rounded,
      isLoading: _viewModel.isLoading,
      body: Column(
        children: [
          FilterTabs(filters: _viewModel.filters, selected: _viewModel.selectedFilter, onSelected: _viewModel.setFilter),
          const SizedBox(height: 12),
          Expanded(
            child: _viewModel.filteredPlots.isEmpty
                ? EmptyState(icon: Icons.domain_disabled_rounded, title: 'No plots found', subtitle: 'No plot matches current search or status filter.', buttonText: 'Reset', onPressed: () { _searchController.clear(); _viewModel.clearSearch(); _viewModel.setFilter('All'); })
                : GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    itemCount: _viewModel.filteredPlots.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.72,
                    ),
                    itemBuilder: (context, index) {
                      final plot = _viewModel.filteredPlots[index];
                      return _PlotCard(plot: plot, onEdit: () => _openEditSheet(plot), onDelete: () => _deletePlot(plot));
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PlotCard extends StatelessWidget {
  final SocietyPlot plot;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PlotCard({required this.plot, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onEdit,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            GradientIconBox(icon: Icons.home_work_rounded, color: plot.status.color, size: 42),
            const Spacer(),
            PopupMenuButton<String>(
              color: AdminColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              onSelected: (value) { if (value == 'edit') onEdit(); if (value == 'delete') onDelete(); },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: PopupMenuRow(icon: Icons.edit_rounded, text: 'Edit Plot')),
                PopupMenuItem(value: 'delete', child: PopupMenuRow(icon: Icons.delete_rounded, text: 'Delete Plot')),
              ],
            ),
          ]),
          const SizedBox(height: 12),
          Text(plot.id, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 21, letterSpacing: -0.6)),
          const SizedBox(height: 8),
          StatusPill(label: plot.status.label, color: plot.status.color),
          const SizedBox(height: 12),
          Text(plot.size, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 4),
          Text(plot.location, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w700, fontSize: 12, height: 1.25)),
          const Spacer(),
          Text(plot.price, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: onEdit, child: const Text('Edit'))),
            const SizedBox(width: 8),
            IconButton.filledTonal(onPressed: onDelete, icon: const Icon(Icons.delete_rounded), color: AdminColors.rejected),
          ]),
        ],
      ),
    );
  }
}
