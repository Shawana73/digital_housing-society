import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/app_snack.dart';

class MapPlotBlock extends StatelessWidget {
  final SocietyPlot plot;
  const MapPlotBlock({super.key, required this.plot});

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

class PlotVisualizationTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const PlotVisualizationTitle({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 18)),
      const SizedBox(height: 4),
      Text(subtitle, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w700)),
    ]);
  }
}