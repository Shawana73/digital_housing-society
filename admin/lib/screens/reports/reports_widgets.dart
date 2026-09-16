import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/premium_widgets.dart';

class DateRangeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const DateRangeChip({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AdminColors.primary.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today_rounded, color: AdminColors.primary, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w800, fontSize: 12.5)),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: AdminColors.greyText, size: 18),
          ]),
        ),
      ),
    );
  }
}


class PeriodDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const PeriodDropdown({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AdminColors.background, borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AdminColors.greyText, size: 16),
          style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w800, fontSize: 12),
          items: const [
            DropdownMenuItem(value: 'Daily', child: Text('Daily')),
            DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
            DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
class ReportsStatsGrid extends StatelessWidget {
  final int totalApplicants;
  final int totalPayments;
  final int verifiedApplicants;
  final int pendingApplicants;
  final int rejectedApplicants;

  const ReportsStatsGrid({
    super.key,
    required this.totalApplicants,
    required this.verifiedApplicants,
    required this.pendingApplicants,
    required this.rejectedApplicants,
    required this.totalPayments,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('Total Applicants', totalApplicants.toString(), AdminColors.primary, Icons.groups_rounded),
      ('Total Payments', totalPayments.toString(), AdminColors.primary, Icons.payments_rounded),
      ('Verified Applicants', verifiedApplicants.toString(), AdminColors.success, Icons.verified_rounded),
      ('Pending Applicants', pendingApplicants.toString(), AdminColors.warning, Icons.hourglass_top_rounded),
      ('Rejected Applicants', rejectedApplicants.toString(), AdminColors.rejected, Icons.cancel_rounded),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: stats.map((stat) {
            return SizedBox(
              width: cardWidth,
              child: PremiumCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 32,
                      width: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: stat.$3.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(stat.$4, color: stat.$3, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            stat.$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AdminColors.darkText,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stat.$1,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AdminColors.greyText,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const LegendDot({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w700, fontSize: 11)),
    ]);
  }
}
class TrendChart extends StatefulWidget {
  final List<String> months;
  final List<double> total;
  final List<double> verified;
  final List<double> rejected;

  const TrendChart({
    super.key,
    required this.months,
    required this.total,
    required this.verified,
    required this.rejected,
  });

  @override
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart> {
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex =
    widget.months.isEmpty ? null : widget.months.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.months.isEmpty) {
      return const Center(
        child: Text(
          'No trend data available',
          style: TextStyle(
            color: AdminColors.greyText,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return GestureDetector(
          onTapDown: (details) {
            if (widget.months.length == 1) {
              setState(() => _selectedIndex = 0);
              return;
            }

            final step = width / (widget.months.length - 1);

            final idx = (details.localPosition.dx / step)
                .round()
                .clamp(0, widget.months.length - 1);

            setState(() => _selectedIndex = idx);
          },
          child: Stack(
            children: [
              CustomPaint(
                size: Size(width, constraints.maxHeight),
                painter: _TrendChartPainter(
                  total: widget.total,
                  verified: widget.verified,
                  rejected: widget.rejected,
                  months: widget.months,
                  selectedIndex: _selectedIndex,
                ),
              ),
              if (_selectedIndex != null)
                _buildTooltip(
                  width,
                  constraints.maxHeight,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTooltip(double width, double height) {
    final i = _selectedIndex!;

    if (i >= widget.months.length) {
      return const SizedBox.shrink();
    }

    final step = widget.months.length == 1
        ? 0.0
        : width / (widget.months.length - 1);

    final x = step * i;

    const tooltipWidth = 150.0;

    double left = x - tooltipWidth / 2;

    left = left.clamp(
      0.0,
      width > tooltipWidth ? width - tooltipWidth : 0.0,
    );

    return Positioned(
      left: left,
      top: 0,
      child: Container(
        width: tooltipWidth,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AdminColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.months[i]} ${DateTime.now().year}',
              style: const TextStyle(
                color: AdminColors.darkText,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            _tooltipRow(
              'Total',
              widget.total[i],
              AdminColors.primary,
            ),
            _tooltipRow(
              'Verified',
              widget.verified[i],
              AdminColors.success,
            ),
            _tooltipRow(
              'Rejected',
              widget.rejected[i],
              AdminColors.rejected,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tooltipRow(
      String label,
      double value,
      Color color,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AdminColors.greyText,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
          Text(
            value.toInt().toString(),
            style: const TextStyle(
              color: AdminColors.darkText,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<double> total;
  final List<double> verified;
  final List<double> rejected;
  final List<String> months;
  final int? selectedIndex;

  _TrendChartPainter({
    required this.total,
    required this.verified,
    required this.rejected,
    required this.months,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const labelSpace = 22.0;
    final chartHeight = size.height - labelSpace;
    final maxV = [
      ...total,
      ...verified,
      ...rejected,
      1.0,
    ].reduce((a, b) => a > b ? a : b) * 1.2;
    final step = months.length > 1 ? size.width / (months.length - 1) : 0.0;

    final gridPaint = Paint()
      ..color = AdminColors.greyText.withOpacity(0.10)
      ..strokeWidth = 1;
    const ySteps = 5;
    for (int i = 0; i <= ySteps; i++) {
      final y = chartHeight * (1 - i / ySteps);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    Offset pointFor(List<double> series, int i) {
      final x = months.length > 1 ? step * i : size.width / 2;
      final y = chartHeight * (1 - (series[i] / maxV));
      return Offset(x, y);
    }

    void drawSeries(List<double> series, Color color, {bool fill = false}) {
      final path = Path();
      for (int i = 0; i < series.length; i++) {
        final p = pointFor(series, i);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      if (fill) {
        final fillPath = Path.from(path);
        fillPath.lineTo(size.width, chartHeight);
        fillPath.lineTo(0, chartHeight);
        fillPath.close();
        canvas.drawPath(fillPath, Paint()..color = color.withOpacity(0.12)..style = PaintingStyle.fill);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 2.4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    drawSeries(total, AdminColors.primary, fill: true);
    drawSeries(verified, AdminColors.success, fill: true);
    drawSeries(rejected, AdminColors.rejected, fill: false);

    if (selectedIndex != null) {
      final i = selectedIndex!;
      final x = step * i;
      final dashPaint = Paint()
        ..color = AdminColors.greyText.withOpacity(0.4)
        ..strokeWidth = 1;
      const dashHeight = 4.0, dashGap = 3.0;
      double y0 = 0;
      while (y0 < chartHeight) {
        canvas.drawLine(Offset(x, y0), Offset(x, (y0 + dashHeight).clamp(0, chartHeight)), dashPaint);
        y0 += dashHeight + dashGap;
      }

      void marker(List<double> series, Color color) {
        final p = pointFor(series, i);
        canvas.drawCircle(p, 5, Paint()..color = AdminColors.white);
        canvas.drawCircle(p, 5, Paint()..color = color..strokeWidth = 2.4..style = PaintingStyle.stroke);
      }

      marker(total, AdminColors.primary);
      marker(verified, AdminColors.success);
      marker(rejected, AdminColors.rejected);
    }

    final labelInterval = months.length > 10 ? (months.length / 8).ceil() : 1;
    for (int i = 0; i < months.length; i++) {
      if (i % labelInterval != 0 && i != months.length - 1) continue;
      final tp = TextPainter(
        text: TextSpan(text: months[i], style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w700, fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = step * i - tp.width / 2;
      tp.paint(canvas, Offset(x.clamp(0, size.width - tp.width), chartHeight + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) => oldDelegate.selectedIndex != selectedIndex;
}

class QuickReportsGrid extends StatelessWidget {
  final void Function(String label) onTap;
  const QuickReportsGrid({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Applicant\nSummary', Icons.groups_rounded),
      ('Payment\nReport', Icons.description_rounded),
      ('Balloting\nReport', Icons.emoji_events_rounded),
      ('Plot Allocation\nReport', Icons.pie_chart_rounded),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 130,
      ),
      itemBuilder: (context, i) {
        final (label, icon) = items[i];
        return PremiumCard(
          onTap: () => onTap(label.replaceAll('\n', ' ')),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(color: AdminColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, color: AdminColors.primary, size: 20),
              ),
              const SizedBox(height: 10),
              Text(label,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w800, fontSize: 12.5, height: 1.25)),
            ],
          ),
        );
      },
    );
  }
}

class RecentReportRow extends StatelessWidget {
  final ReportCardModel report;
  final VoidCallback onTap;

  const RecentReportRow({
    super.key,
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isExcel = report.fileType.toUpperCase() == 'XLSX' || report.fileType.toUpperCase() == 'EXCEL';
    final fileColor = isExcel ? AdminColors.success : AdminColors.rejected;
    final fileIcon = isExcel ? Icons.table_chart_rounded : Icons.picture_as_pdf_rounded;

    return PremiumCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(color: fileColor.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(fileIcon, color: fileColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w800, fontSize: 13.5)),
                const SizedBox(height: 3),
                Text(report.subtitle,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: fileColor.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
            child: Text(report.fileType.toUpperCase(), style: TextStyle(color: fileColor, fontWeight: FontWeight.w800, fontSize: 10.5)),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onTap,
            icon: const Icon(
              Icons.visibility_rounded,
              color: AdminColors.primary,
            ),
            tooltip: 'View Details',
          ),
        ],
      ),
    );
  }
}
