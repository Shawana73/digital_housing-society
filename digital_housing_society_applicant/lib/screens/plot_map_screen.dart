import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/plot_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_assets.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../widgets/header_actions.dart';
import '../widgets/status_badge.dart';

class PlotMapScreen extends StatelessWidget {
  const PlotMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: const Text('Static Plot Map'), actions: const [NotificationBell(), SizedBox(width: 8)]),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(AppAssets.staticPlotMap, height: 250, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),
          Text('Available Plot Overview', style: AppTextStyles.headingSmall),
          const SizedBox(height: 10),
          Text('Static society map and plot records are shown here after they are published in Firestore.', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: service.getPlots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple));
              final plots = (snapshot.data?.docs ?? []).map(PlotModel.fromFirestore).toList();
              if (snapshot.hasError) return const _EmptyPlots(text: 'Plot records could not be loaded.');
              if (plots.isEmpty) return const _EmptyPlots(text: 'No plot records have been published yet.');
              return LayoutBuilder(builder: (context, constraints) {
                final width = constraints.maxWidth < 460 ? constraints.maxWidth : (constraints.maxWidth - 14) / 2;
                return Wrap(spacing: 14, runSpacing: 14, children: plots.map((p) => SizedBox(width: width, child: _PlotCard(plot: p))).toList());
              });
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyPlots extends StatelessWidget {
  const _EmptyPlots({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.borderColor)),
      child: Row(children: [const Icon(Icons.map_outlined, color: AppColors.hintText), const SizedBox(width: 12), Expanded(child: Text(text, style: AppTextStyles.bodyMedium))]),
    );
  }
}

class _PlotCard extends StatelessWidget {
  const _PlotCard({required this.plot});
  final PlotModel plot;

  @override
  Widget build(BuildContext context) {
    final status = plot.status.isEmpty ? 'available' : plot.status;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.borderColor), boxShadow: AppColors.premiumShadow(opacity: .16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(backgroundColor: AppColors.lightPurpleBackground, child: const Icon(Icons.location_on_rounded, color: AppColors.deepPurple)),
          const SizedBox(width: 10),
          Expanded(child: Text(plot.plotNumber, style: AppTextStyles.headingSmall)),
          StatusBadge(text: status.toUpperCase(), type: badgeTypeFromStatus(status)),
        ]),
        const SizedBox(height: 12),
        _row('Type', plot.plotType),
        _row('Location', plot.location),
        _row('Price', NumberFormat.currency(locale: 'en_PK', symbol: 'PKR ', decimalDigits: 0).format(plot.price)),
      ]),
    );
  }

  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [Text(label, style: AppTextStyles.captionText), const Spacer(), Flexible(child: Text(value.isEmpty ? '-' : value, textAlign: TextAlign.right, style: AppTextStyles.labelBold))]));
}
