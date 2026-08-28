import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/plot_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_text_styles.dart';
import '../widgets/header_actions.dart';
import '../widgets/status_badge.dart';

class PlotMapScreen extends StatefulWidget {
  const PlotMapScreen({super.key});

  @override
  State<PlotMapScreen> createState() => _PlotMapScreenState();
}

class _PlotMapScreenState extends State<PlotMapScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plot Map'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
            onSelected: (value) {
              setState(() => _filter = value);
            },
            itemBuilder: (_) {
              return ['All', '3 Marla', '5 Marla', '10 Marla']
                  .map(
                    (item) => PopupMenuItem<String>(
                  value: item,
                  child: Text(item),
                ),
              )
                  .toList();
            },
          ),
          const NotificationBell(),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getPlots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryPurple,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load plots. Please try again.',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final firebasePlots = snapshot.data?.docs
                  .map((doc) => PlotModel.fromFirestore(doc))
                  .toList() ??
              [];

          final plots = firebasePlots.isEmpty ? _demoPlots(uid) : firebasePlots;

          final filtered = _filter == 'All'
              ? plots
              : plots.where((plot) => plot.plotType == _filter).toList();

          final available = plots
              .where((plot) => plot.status.toLowerCase() == 'available')
              .length;

          final booked = plots
              .where((plot) => plot.status.toLowerCase() == 'booked')
              .length;

          final yourPlot =
              plots.where((plot) => plot.allocatedTo == uid).length;

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: AppColors.premiumShadow(opacity: .25),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: CustomPaint(
                    painter: AerialMapPainter(
                      plots: plots,
                      uid: uid,
                    ),
                    child: Container(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['All', '3 Marla', '5 Marla', '10 Marla']
                      .map((tab) {
                    final active = _filter == tab;

                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(tab),
                        selected: active,
                        onSelected: (_) {
                          setState(() => _filter = tab);
                        },
                        selectedColor: AppColors.primaryPurple,
                        labelStyle: AppTextStyles.labelBold.copyWith(
                          color: active
                              ? AppColors.white
                              : AppColors.secondaryText,
                        ),
                        backgroundColor: AppColors.lightPurpleBackground,
                        side: BorderSide.none,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  _StatCard(
                    label: 'Available',
                    value: '$available',
                    color: AppColors.successGreen,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    label: 'Booked',
                    value: '$booked',
                    color: AppColors.errorRed,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    label: 'Your Plot',
                    value: '$yourPlot',
                    color: AppColors.primaryPurple,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              if (filtered.isEmpty)
                const _EmptyMap()
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth < 360 ? 4 : constraints.maxWidth < 520 ? 5 : 6;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: .9,
                      ),
                      itemBuilder: (context, index) {
                    final plot = filtered[index];
                    final isMine = plot.allocatedTo == uid;

                    return _PlotCell(
                      plot: plot,
                      isMine: isMine,
                      onTap: () => _showPlotSheet(context, plot, isMine),
                    );
                      },
                    );
                  },
                ),

              const SizedBox(height: 18),
              const _LegendCard(),
            ],
          );
        },
      ),
    );
  }

  List<PlotModel> _demoPlots(String uid) {
    const types = AppConstants.plotTypes;
    return List.generate(24, (index) {
      final type = types[index % types.length];
      final status = index % 7 == 0 ? 'booked' : index % 11 == 0 ? 'reserved' : 'available';
      return PlotModel(
        id: 'demo_${index + 1}',
        plotNumber: 'P-${(index + 1).toString().padLeft(2, '0')}',
        plotType: type,
        size: type,
        location: 'Block ${String.fromCharCode(65 + (index ~/ 6))}',
        price: AppConstants.plotFeeMap[type] ?? 0,
        status: status,
        allocatedTo: '',
      );
    });
  }

  void _showPlotSheet(BuildContext context, PlotModel plot, bool isMine) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Icon(
                  Icons.house_rounded,
                  size: 72,
                  color: _plotColor(plot, isMine),
                ),
              ),

              if (isMine)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightPurpleBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'This is YOUR plot!',
                    style: AppTextStyles.labelBold.copyWith(
                      color: AppColors.deepPurple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 16),

              Text(
                'Plot ${plot.plotNumber}',
                style: AppTextStyles.headingMedium,
              ),

              const SizedBox(height: 12),

              _detail('Plot Type', plot.plotType),
              _detail('Size', plot.size),
              _detail('Location', plot.location),
              _detail(
                'Price',
                NumberFormat.currency(
                  locale: 'en_PK',
                  symbol: 'PKR ',
                  decimalDigits: 0,
                ).format(plot.price),
              ),

              const SizedBox(height: 8),

              StatusBadge(
                text: plot.status.toUpperCase(),
                type: badgeTypeFromStatus(plot.status),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.captionText,
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value.isEmpty ? '-' : value,
              style: AppTextStyles.labelBold,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class AerialMapPainter extends CustomPainter {
  AerialMapPainter({
    required this.plots,
    required this.uid,
  });

  final List<PlotModel> plots;
  final String uid;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0F3D2E),
    );

    final roadPaint = Paint()
      ..color = const Color(0xFF7B8794)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    for (var i = 1; i < 4; i++) {
      canvas.drawLine(
        Offset(0, size.height * i / 4),
        Offset(size.width, size.height * i / 4),
        roadPaint,
      );
    }

    for (var i = 1; i < 5; i++) {
      canvas.drawLine(
        Offset(size.width * i / 5, 0),
        Offset(size.width * i / 5, size.height),
        roadPaint,
      );
    }

    final limited = plots.take(18).toList();

    for (var i = 0; i < limited.length; i++) {
      final plot = limited[i];
      final col = i % 6;
      final row = i ~/ 6;

      final rect = Rect.fromLTWH(
        12 + col * (size.width - 24) / 6,
        20 + row * 44,
        (size.width - 60) / 6,
        28,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect,
          const Radius.circular(5),
        ),
        Paint()..color = _plotColor(plot, plot.allocatedTo == uid),
      );
    }

    for (var i = 0; i < 12; i++) {
      final x = 20 + (i * 47) % size.width;
      final y = 20 + (i * 31) % size.height;

      canvas.drawCircle(
        Offset(x, y),
        5,
        Paint()..color = const Color(0xFF14532D),
      );
    }

    final mineIndex = plots.indexWhere((plot) => plot.allocatedTo == uid);

    if (mineIndex >= 0) {
      final pin = Offset(size.width * .72, size.height * .45);

      canvas.drawCircle(
        pin,
        10,
        Paint()..color = AppColors.gold,
      );

      canvas.drawPath(
        Path()
          ..moveTo(pin.dx, pin.dy + 26)
          ..lineTo(pin.dx - 8, pin.dy + 8)
          ..lineTo(pin.dx + 8, pin.dy + 8)
          ..close(),
        Paint()..color = AppColors.gold,
      );

      final label = Rect.fromCenter(
        center: Offset(pin.dx, pin.dy - 28),
        width: 76,
        height: 24,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          label,
          const Radius.circular(8),
        ),
        Paint()..color = AppColors.darkNavy,
      );

      final tp = TextPainter(
        text: const TextSpan(
          text: 'YOUR PLOT',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        Offset(
          label.center.dx - tp.width / 2,
          label.center.dy - tp.height / 2,
        ),
      );
    }

    final block = TextPainter(
      text: const TextSpan(
        text: 'Block A — Phase 1',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    block.paint(canvas, const Offset(14, 12));

    canvas.drawCircle(
      Offset(size.width - 28, size.height - 28),
      18,
      Paint()..color = Colors.white.withValues(alpha: .85),
    );

    final compass = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    compass.paint(
      canvas,
      Offset(
        size.width - 28 - compass.width / 2,
        size.height - 28 - compass.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant AerialMapPainter oldDelegate) {
    return oldDelegate.plots != plots || oldDelegate.uid != uid;
  }
}

Color _plotColor(PlotModel plot, bool isMine) {
  if (isMine) return AppColors.lavender;

  final status = plot.status.toLowerCase();

  if (status == 'available') return AppColors.successGreen;
  if (status == 'booked') return AppColors.errorRed;

  return AppColors.reservedGrey;
}

class _PlotCell extends StatelessWidget {
  const _PlotCell({
    required this.plot,
    required this.isMine,
    required this.onTap,
  });

  final PlotModel plot;
  final bool isMine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _plotColor(plot, isMine);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: .16),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color,
            width: 1.3,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_rounded,
              size: 16,
              color: color,
            ),
            const SizedBox(height: 2),
            Text(
              plot.plotNumber,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.captionText.copyWith(
                fontSize: 9,
                color: AppColors.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.headingSmall.copyWith(
                color: color,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.captionText,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendCard extends StatelessWidget {
  const _LegendCard();

  @override
  Widget build(BuildContext context) {
    final items = <MapEntry<String, Color>>[
      MapEntry('Available', AppColors.successGreen),
      MapEntry('Booked', AppColors.errorRed),
      MapEntry('Your Plot', AppColors.lavender),
      MapEntry('Reserved', AppColors.reservedGrey),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.borderColor,
        ),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 10,
        children: items.map((item) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: item.value,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                item.key,
                style: AppTextStyles.captionText,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyMap extends StatelessWidget {
  const _EmptyMap();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.borderColor,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.map_outlined,
            size: 60,
            color: AppColors.hintText,
          ),
          const SizedBox(height: 8),
          Text(
            'No plots found',
            style: AppTextStyles.headingSmall,
          ),
          Text(
            'Plots added by admin will appear here.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}