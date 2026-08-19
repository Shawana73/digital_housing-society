import 'package:flutter/material.dart';
import '../models/plot_model.dart';
import '../app_routes.dart';
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

  void _openEditSheet(PlotModel plot) {
    final statuses = ['Available', 'Booked', 'Allocated'];

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AdminColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SectionHeader(
              title: 'Edit ${plot.plotId}',
              subtitle: 'Change plot status',
            ),

            ...statuses.map(
                  (status) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PremiumCard(
                  onTap: () async {
                    Navigator.pop(context);

                    await _viewModel.updateStatus(
                      plot,
                      status,
                    );

                    if (mounted) {
                      showAdminSnack(
                        context,
                        '${plot.plotId} marked $status',
                      );
                    }
                  },
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const GradientIconBox(
                        icon: Icons.circle_rounded,
                        color: AdminColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          status,
                          style: const TextStyle(
                            color: AdminColors.darkText,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (plot.status == status)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AdminColors.primary,
                        ),
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
  final PlotModel plot;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PlotCard({
    required this.plot,
    required this.onEdit,
    required this.onDelete,
  });

  Color _statusColor() {
    switch (plot.status.toLowerCase()) {
      case 'available':
        return AdminColors.success;
      case 'booked':
        return AdminColors.warning;
      case 'allocated':
        return AdminColors.primary;
      default:
        return AdminColors.greyText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();

    return PremiumCard(
      onTap: onEdit,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GradientIconBox(
                icon: Icons.home_work_rounded,
                color: statusColor,
                size: 42,
              ),
              const Spacer(),
              PopupMenuButton<String>(
                color: AdminColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(18),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  }

                  if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: PopupMenuRow(
                      icon: Icons.edit_rounded,
                      text: 'Edit Plot',
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: PopupMenuRow(
                      icon: Icons.delete_rounded,
                      text: 'Delete Plot',
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            plot.plotId,
            style: const TextStyle(
              color: AdminColors.darkText,
              fontWeight: FontWeight.w900,
              fontSize: 21,
              letterSpacing: -0.6,
            ),
          ),

          const SizedBox(height: 8),

          StatusPill(
            label: plot.status,
            color: statusColor,
          ),

          const SizedBox(height: 12),

          Text(
            plot.plotSize,
            style: const TextStyle(
              color: AdminColors.darkText,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            plot.location,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AdminColors.greyText,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              height: 1.25,
            ),
          ),

          const Spacer(),

          Text(
            'PKR ${plot.price.toStringAsFixed(0)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AdminColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onEdit,
                  child: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_rounded,
                ),
                color: AdminColors.rejected,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
