import 'package:flutter/material.dart';
import '../../models/plot_model.dart';
import '../../app_routes.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_shell.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/premium_widgets.dart';
import 'plot_viewmodel.dart';
import 'plot_widgets.dart';

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

  void _openEditSheet(PlotModel plot) {
    final statuses = ['Available', 'Booked', 'Allocated'];

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
            SectionHeader(title: 'Edit ${plot.plotId}', subtitle: 'Change plot status'),
            ...statuses.map(
                  (status) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PremiumCard(
                  onTap: () async {
                    Navigator.pop(context);
                    await _viewModel.updateStatus(plot, status);
                    if (mounted) showAdminSnack(context, '${plot.plotId} marked $status');
                  },
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const GradientIconBox(icon: Icons.circle_rounded, color: AdminColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(status, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900)),
                      ),
                      if (plot.status == status)
                        const Icon(Icons.check_circle_rounded, color: AdminColors.primary),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePlot(PlotModel plot) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminColors.radius)),
        title: Text('Delete ${plot.plotId}?'),
        content: const Text('This will remove the plot from local dummy list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      _viewModel.deletePlot(plot);
      if (mounted) showAdminSnack(context, '${plot.plotId} deleted');
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
                ? EmptyState(
                icon: Icons.domain_disabled_rounded,
                title: 'No plots found',
                subtitle: 'No plot matches current search or status filter.',
                buttonText: 'Reset',
                onPressed: () { _searchController.clear(); _viewModel.clearSearch(); _viewModel.setFilter('All'); })
                : GridView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              itemCount: _viewModel.filteredPlots.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.50,
              ),
              itemBuilder: (context, index) {
                final plot = _viewModel.filteredPlots[index];
                return PlotCard(plot: plot, onEdit: () => _openEditSheet(plot), onDelete: () => _deletePlot(plot));
              },
            ),
          ),
        ],
      ),
    );
  }
}