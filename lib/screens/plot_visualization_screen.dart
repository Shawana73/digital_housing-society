import 'package:flutter/material.dart';

import '../models/admin_models.dart';
import '../theme/admin_theme.dart';
import '../viewmodels/admin_view_models.dart';
import '../widgets/admin_shell.dart';
import '../widgets/app_snack.dart';
import '../widgets/premium_widgets.dart';

class PlotVisualizationScreen extends StatefulWidget {
  const PlotVisualizationScreen({super.key});

  @override
  State<PlotVisualizationScreen> createState() => _PlotVisualizationScreenState();
}

class _PlotVisualizationScreenState extends State<PlotVisualizationScreen> {
  final PlotVisualizationViewModel _viewModel = PlotVisualizationViewModel();
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

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Plot Visualization',
      selectedIndex: 0,
      searchController: _searchController,
      searchHint: 'Search plot on map...',
      onSearchChanged: _viewModel.search,
      onSearchClear: () { _searchController.clear(); _viewModel.clearSearch(); },
      onFabTap: () => showAdminSnack(context, 'Map centered'),
      fabLabel: 'Center',
      fabIcon: Icons.my_location_rounded,
      isLoading: _viewModel.isLoading,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        children: [
          PremiumCard(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const GradientIconBox(icon: Icons.map_rounded, size: 54),
                const SizedBox(width: 12),
                const Expanded(child: _Title(title: 'Modern Map Layout', subtitle: 'Tap any plot block to view status')),
                Column(children: [
                  IconButton.filled(onPressed: _viewModel.zoomIn, icon: const Icon(Icons.add_rounded)),
                  const SizedBox(height: 6),
                  IconButton.filledTonal(onPressed: _viewModel.zoomOut, icon: const Icon(Icons.remove_rounded)),
                ]),
              ]),
              const SizedBox(height: 12),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusPill(label: 'Available', color: AdminColors.success),
                  StatusPill(label: 'Booked', color: AdminColors.warning),
                  StatusPill(label: 'Allocated', color: AdminColors.primary),
                ],
              ),
            ]),
          ),
          const SizedBox(height: 16),
          AnimatedScale(
            scale: _viewModel.zoom,
            duration: const Duration(milliseconds: 250),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AdminColors.white.withOpacity(0.72),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AdminColors.primary.withOpacity(0.08)),
              ),
              child: _viewModel.filteredPlots.isEmpty
                  ? EmptyState(icon: Icons.map_outlined, title: 'No plot found', subtitle: 'No map block matches your search.', buttonText: 'Reset', onPressed: () { _searchController.clear(); _viewModel.clearSearch(); })
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _viewModel.filteredPlots.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.95,
                      ),
                      itemBuilder: (context, index) {
                        final plot = _viewModel.filteredPlots[index];
                        return _MapPlotBlock(plot: plot);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPlotBlock extends StatelessWidget {
  final SocietyPlot plot;
  const _MapPlotBlock({required this.plot});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: plot.status.color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => showAdminSnack(context, '${plot.id} - ${plot.status.label}'),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: plot.status.color.withOpacity(0.32)),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.home_work_rounded, color: plot.status.color),
            const SizedBox(height: 8),
            Text(plot.id, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(plot.size, textAlign: TextAlign.center, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w700, fontSize: 11)),
          ]),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Title({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 18)),
      const SizedBox(height: 4),
      Text(subtitle, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w700)),
    ]);
  }
}
