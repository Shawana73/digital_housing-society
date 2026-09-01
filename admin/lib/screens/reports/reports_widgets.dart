import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/app_snack.dart';
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

class ReportsFilterChip extends StatelessWidget {
  final VoidCallback onTap;
  const ReportsFilterChip({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AdminColors.primary.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.tune_rounded, color: AdminColors.primary, size: 16),
            SizedBox(width: 7),
            Text('Filter', style: TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w800, fontSize: 12.5)),
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
  const ReportsStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('Total Applicants', '1,284', '+12.8%', true, AdminColors.primary, Icons.groups_rounded),
      ('Verified Applicants', '842', '+16.2%', true, AdminColors.success, Icons.verified_rounded),
      ('Pending Applicants', '356', '+8.4%', true, AdminColors.warning, Icons.hourglass_top_rounded),
      ('Rejected Applicants', '86', '-2.1%', false, AdminColors.rejected, Icons.cancel_rounded),
    ];

    return Column(
      children: [
        for (int i = 0; i < stats.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < stats.length ? 12 : 0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: ReportStatCard(data: stats[i])),
                  const SizedBox(width: 12),
                  Expanded(child: i + 1 < stats.length ? ReportStatCard(data: stats[i + 1]) : const SizedBox.shrink()),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class ReportStatCard extends StatelessWidget {
  final (String, String, String, bool, Color, IconData) data;
  const ReportStatCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final (title, value, trend, isUp, color, icon) = data;
    return PremiumCard(
      onTap: () => showAdminSnack(context, '$title clicked'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(13)),
              child: Icon(icon, color: color, size: 20),
            ),
          ]),
          const SizedBox(height: 12),
          Text(title,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -.5)),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: (isUp ? AdminColors.success : AdminColors.rejected).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(trend,
                    style: TextStyle(color: isUp ? AdminColors.success : AdminColors.rejected, fontWeight: FontWeight.w800, fontSize: 11)),
                const SizedBox(width: 2),
                Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    color: isUp ? AdminColors.success : AdminColors.rejected, size: 12),
              ]),
            ),
          ),
        ],
      ),
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
  const TrendChart({super.key});

  @override
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart> {
  int? _selectedIndex;

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
  static const _total = [620.0, 780.0, 850.0, 1080.0, 1124.0, 1284.0];
  static const _verified = [380.0, 470.0, 520.0, 690.0, 742.0, 842.0];
  static const _rejected = [40.0, 52.0, 58.0, 60.0, 64.0, 86.0];

  @override
  void initState() {
    super.initState();
    _selectedIndex = 4;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      return GestureDetector(
        onTapDown: (details) {
          final step = width / (_months.length - 1);
          final idx = (details.localPosition.dx / step).round().clamp(0, _months.length - 1);
          setState(() => _selectedIndex = idx);
        },
        child: Stack(children: [
          CustomPaint(
            size: Size(width, constraints.maxHeight),
            painter: _TrendChartPainter(
              total: _total,
              verified: _verified,
              rejected: _rejected,
              months: _months,
              selectedIndex: _selectedIndex,
            ),
          ),
          if (_selectedIndex != null) _buildTooltip(width, constraints.maxHeight),
        ]),
      );
    });
  }

  Widget _buildTooltip(double width, double height) {
    final i = _selectedIndex!;
    final step = width / (_months.length - 1);
    final x = step * i;
    const tooltipWidth = 150.0;
    double left = x - tooltipWidth / 2;
    left = left.clamp(0, width - tooltipWidth);

    return Positioned(
      left: left,
      top: 0,
      child: Container(
        width: tooltipWidth,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AdminColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${_months[i]} 2026', style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 11)),
            const SizedBox(height: 6),
            _tooltipRow('Total', _total[i], AdminColors.primary),
            _tooltipRow('Verified', _verified[i], AdminColors.success),
            _tooltipRow('Rejected', _rejected[i], AdminColors.rejected),
          ],
        ),
      ),
    );
  }

  Widget _tooltipRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Expanded(child: Text(label, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 10))),
        Text(value.toInt().toString(), style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w800, fontSize: 10)),
      ]),
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
    const maxV = 1500.0;
    final step = size.width / (months.length - 1);

    final gridPaint = Paint()
      ..color = AdminColors.greyText.withOpacity(0.10)
      ..strokeWidth = 1;
    const ySteps = 5;
    for (int i = 0; i <= ySteps; i++) {
      final y = chartHeight * (1 - i / ySteps);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    Offset pointFor(List<double> series, int i) {
      final x = step * i;
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

    for (int i = 0; i < months.length; i++) {
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
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.25,
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
  const RecentReportRow({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final isExcel = report.fileType.toUpperCase() == 'XLSX' || report.fileType.toUpperCase() == 'EXCEL';
    final fileColor = isExcel ? AdminColors.success : AdminColors.rejected;
    final fileIcon = isExcel ? Icons.table_chart_rounded : Icons.picture_as_pdf_rounded;

    return PremiumCard(
      onTap: () => showAdminSnack(context, '${report.title} opened'),
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
          RoundDownloadButton(onTap: () => showAdminSnack(context, '${report.title} downloading...')),
        ],
      ),
    );
  }
}

class RoundDownloadButton extends StatelessWidget {
  final VoidCallback onTap;
  const RoundDownloadButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminColors.background,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          height: 36,
          width: 36,
          alignment: Alignment.center,
          child: const Icon(Icons.download_rounded, color: AdminColors.primary, size: 18),
        ),
      ),
    );
  }
}

class ReportsSheetOption extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const ReportsSheetOption({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PremiumCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w800, fontSize: 14))),
          const Icon(Icons.chevron_right_rounded, color: AdminColors.greyText, size: 18),
        ]),
      ),
    );
  }
}