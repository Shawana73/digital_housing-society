import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../theme/admin_theme.dart';
class MapPlotBlock extends StatelessWidget {
  final SocietyPlot plot;

  const MapPlotBlock({
    super.key,
    required this.plot,
  });

  void _showPlotDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.home_work_rounded,
                color: plot.status.color,
              ),
              const SizedBox(width: 10),
              Text(plot.id),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Status', plot.status.label),
              _detailRow('Plot Size', plot.size),
              _detailRow('Location', plot.location),
              _detailRow('Price', plot.price),
              _detailRow(
                'Description',
                plot.description.isEmpty
                    ? 'No description available'
                    : plot.description,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              title,
              style: const TextStyle(
                color: AdminColors.greyText,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: AdminColors.darkText,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showPlotDetails(context),
        borderRadius: BorderRadius.circular(5),
        child: Container(
          decoration: BoxDecoration(
            color: plot.status.color.withOpacity(0.14),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: plot.status.color.withOpacity(0.8),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.home_work_rounded,
                size: 13,
                color: plot.status.color,
              ),
              const SizedBox(height: 2),
              Text(
                plot.id,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AdminColors.darkText,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints a dashed center-line marking for a road segment.
class _DashedLinePainter extends CustomPainter {
  final bool vertical;

  const _DashedLinePainter({required this.vertical});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    const dash = 6.0;
    const gap = 5.0;

    if (vertical) {
      final x = size.width / 2;
      double y = 2;
      while (y < size.height - 2) {
        canvas.drawLine(Offset(x, y), Offset(x, y + dash), paint);
        y += dash + gap;
      }
    } else {
      final y = size.height / 2;
      double x = 2;
      while (x < size.width - 2) {
        canvas.drawLine(Offset(x, y), Offset(x + dash, y), paint);
        x += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.vertical != vertical;
  }
}

/// Paints a soft scatter of landscaping dots (trees) used around roads/park.
class _TreeScatterPainter extends CustomPainter {
  final int count;

  const _TreeScatterPainter({this.count = 6});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF6FA66A);
    for (int i = 0; i < count; i++) {
      final dx = size.width * ((i + 1) / (count + 1));
      final dy = size.height * (i.isEven ? 0.3 : 0.7);
      canvas.drawCircle(Offset(dx, dy), 2.4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TreeScatterPainter oldDelegate) => false;
}

class SocietyLayoutMap extends StatelessWidget {
  final List<SocietyPlot> plots;

  const SocietyLayoutMap({
    super.key,
    required this.plots,
  });

  SocietyPlot? _findPlot(String id) {
    for (final plot in plots) {
      if (plot.id.toLowerCase() == id.toLowerCase()) {
        return plot;
      }
    }

    return null;
  }

  List<SocietyPlot> _plotsForBlock(String blockLetter) {
    return plots.where((p) {
      final prefix = p.id.split('-').first.trim().toUpperCase();
      return prefix == blockLetter.toUpperCase();
    }).toList();
  }

  Widget _road({
    String? label,
    bool vertical = false,
    bool main = false,
  }) {
    final asphalt = main ? const Color(0xFFD5D6DB) : const Color(0xFFE2E3E7);
    final edge = const Color(0xFFEFEFF1);

    return Container(
      decoration: BoxDecoration(
        color: asphalt,
        border: vertical
            ? Border(
          left: BorderSide(color: edge, width: 3),
          right: BorderSide(color: edge, width: 3),
        )
            : Border(
          top: BorderSide(color: edge, width: 3),
          bottom: BorderSide(color: edge, width: 3),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _DashedLinePainter(vertical: vertical),
            ),
          ),
          if (label != null)
            Positioned(
              left: vertical ? 0 : 6,
              right: vertical ? 0 : null,
              top: vertical ? 6 : 0,
              bottom: vertical ? null : 0,
              child: Align(
                alignment: vertical ? Alignment.topCenter : Alignment.centerLeft,
                child: RotatedBox(
                  quarterTurns: vertical ? 1 : 0,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF83868D),
                      fontSize: 6,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _block({
    required String title,
    required String blockLetter,
  }) {
    final blockPlots = _plotsForBlock(blockLetter);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFD8D3EC),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AdminColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AdminColors.primary,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: blockPlots.isEmpty
                ? const Center(
              child: Text(
                'No plots yet',
                style: TextStyle(
                  color: Color(0xFFAEB0B5),
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
                : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: blockPlots.map((plot) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: SizedBox(
                      width: 38,
                      child: MapPlotBlock(plot: plot),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _park({required String title}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE1F0DD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFB7CFB7),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: const _TreeScatterPainter(count: 6),
            ),
          ),
          Center(
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0xFFCFE8CC),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF9DC79A), width: 1),
              ),
              child: const Icon(
                Icons.park_rounded,
                color: Color(0xFF52754F),
                size: 15,
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            left: 0,
            right: 0,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF3E5B3A),
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _greenArea(String label) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE5F0E2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFC5DCC1),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF71936C),
          fontSize: 7,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _entrance() {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AdminColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 3, height: 14, color: AdminColors.primary.withOpacity(0.4)),
              const SizedBox(width: 6),
              const Icon(
                Icons.apartment_rounded,
                color: AdminColors.primary,
                size: 20,
              ),
              const SizedBox(width: 6),
              Container(width: 3, height: 14, color: AdminColors.primary.withOpacity(0.4)),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'SOCIETY ENTRANCE',
            style: TextStyle(
              color: AdminColors.primary,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _northIndicator() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: AdminColors.primary.withOpacity(0.25),
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_upward_rounded,
              color: AdminColors.primary,
              size: 12,
            ),
            Text(
              'N',
              style: TextStyle(
                color: AdminColors.primary,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD1D3D6),
        ),
      ),
      child: AspectRatio(
        aspectRatio: 0.72,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            return Stack(
              children: [
                // GREEN PERIMETER
                Positioned(
                  left: width * 0.01,
                  right: width * 0.01,
                  top: height * 0.01,
                  bottom: height * 0.01,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF5EC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFC9D8C4),
                        width: 1,
                      ),
                    ),
                  ),
                ),

                // MAIN HORIZONTAL BOULEVARD
                Positioned(
                  left: width * 0.03,
                  right: width * 0.03,
                  top: height * 0.19,
                  height: height * 0.065,
                  child: _road(
                    label: 'MAIN BOULEVARD',
                    main: true,
                  ),
                ),

                // MAIN VERTICAL ROAD
                Positioned(
                  left: width * 0.46,
                  top: height * 0.08,
                  bottom: height * 0.07,
                  width: width * 0.08,
                  child: _road(
                    label: 'MAIN ROAD',
                    vertical: true,
                    main: true,
                  ),
                ),

                // SECONDARY ROADS
                Positioned(
                  left: width * 0.03,
                  right: width * 0.03,
                  top: height * 0.41,
                  height: height * 0.045,
                  child: _road(),
                ),
                Positioned(
                  left: width * 0.03,
                  right: width * 0.03,
                  top: height * 0.67,
                  height: height * 0.045,
                  child: _road(),
                ),

                // SIDE ROADS
                Positioned(
                  left: width * 0.22,
                  top: height * 0.19,
                  bottom: height * 0.07,
                  width: width * 0.035,
                  child: _road(vertical: true),
                ),
                Positioned(
                  right: width * 0.22,
                  top: height * 0.19,
                  bottom: height * 0.07,
                  width: width * 0.035,
                  child: _road(vertical: true),
                ),

                // ENTRANCE
                Positioned(
                  left: width * 0.29,
                  right: width * 0.29,
                  top: height * 0.035,
                  height: height * 0.105,
                  child: _entrance(),
                ),

                // BLOCK A
                Positioned(
                  left: width * 0.055,
                  top: height * 0.25,
                  width: width * 0.31,
                  height: height * 0.13,
                  child: _block(title: 'BLOCK A', blockLetter: 'A'),
                ),

                // BLOCK C
                Positioned(
                  right: width * 0.055,
                  top: height * 0.25,
                  width: width * 0.31,
                  height: height * 0.13,
                  child: _block(title: 'BLOCK C', blockLetter: 'C'),
                ),

                // CENTRAL PARK
                Positioned(
                  left: width * 0.28,
                  right: width * 0.28,
                  top: height * 0.43,
                  height: height * 0.14,
                  child: _park(title: 'CENTRAL PARK'),
                ),

                // BLOCK D
                Positioned(
                  left: width * 0.055,
                  right: width * 0.055,
                  top: height * 0.60,
                  height: height * 0.13,
                  child: _block(title: 'BLOCK D', blockLetter: 'D'),
                ),

                // GREEN AREA LEFT
                Positioned(
                  left: width * 0.055,
                  top: height * 0.76,
                  width: width * 0.18,
                  height: height * 0.10,
                  child: _greenArea('GREEN\nBELT'),
                ),

                // BLOCK E
                Positioned(
                  left: width * 0.27,
                  top: height * 0.76,
                  width: width * 0.20,
                  height: height * 0.10,
                  child: _block(title: 'BLOCK E', blockLetter: 'E'),
                ),

                // BLOCK G
                Positioned(
                  right: width * 0.055,
                  top: height * 0.76,
                  width: width * 0.20,
                  height: height * 0.10,
                  child: _block(title: 'BLOCK G', blockLetter: 'G'),
                ),

                // BLOCK P
                Positioned(
                  left: width * 0.31,
                  right: width * 0.31,
                  bottom: height * 0.015,
                  height: height * 0.10,
                  child: _block(title: 'BLOCK P', blockLetter: 'P'),
                ),

                // NORTH
                Positioned(
                  right: width * 0.035,
                  top: height * 0.025,
                  child: _northIndicator(),
                ),

                // SITE PLAN LABEL
                Positioned(
                  left: width * 0.045,
                  top: height * 0.035,
                  child: const Text(
                    'MASTER PLAN',
                    style: TextStyle(
                      color: Color(0xFF6E7177),
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class PlotVisualizationTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const PlotVisualizationTitle({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AdminColors.darkText,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: AdminColors.greyText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}