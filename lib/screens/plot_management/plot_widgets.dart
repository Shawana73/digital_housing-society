import 'package:flutter/material.dart';
import '../../models/plot_model.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/premium_widgets.dart';

class PlotCard extends StatelessWidget {
  final PlotModel plot;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PlotCard({
    super.key,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GradientIconBox(icon: Icons.home_work_rounded, color: statusColor, size: 42),
              const Spacer(),
              PopupMenuButton<String>(
                color: AdminColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: PopupMenuRow(icon: Icons.edit_rounded, text: 'Edit Plot')),
                  PopupMenuItem(value: 'delete', child: PopupMenuRow(icon: Icons.delete_rounded, text: 'Delete Plot')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(plot.plotId,
              style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 21, letterSpacing: -0.6)),
          const SizedBox(height: 8),
          StatusPill(label: plot.status, color: statusColor),
          const SizedBox(height: 12),
          Text(plot.plotSize,
              style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 4),
          Text(plot.location,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w700, fontSize: 12, height: 1.25)),
          const Spacer(),
          Text('PKR ${plot.price.toStringAsFixed(0)}',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: onEdit, child: const Text('Edit'))),
              const SizedBox(width: 8),
              IconButton.filledTonal(onPressed: onDelete, icon: const Icon(Icons.delete_rounded), color: AdminColors.rejected),
            ],
          ),
        ],
      ),
    );
  }
}