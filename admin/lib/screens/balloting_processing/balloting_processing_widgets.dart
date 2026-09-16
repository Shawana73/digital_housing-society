import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/admin_theme.dart';

class ProcessingControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  const ProcessingControlBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.38,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: enabled
                  ? [BoxShadow(color: color.withOpacity(0.32), blurRadius: 14, offset: const Offset(0, 6))]
                  : [],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 7),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
        ]),
      ),
    );
  }
}

class ProcessingStep {
  final int number;
  final String title;
  final String subtitle;
  final bool completed;
  final bool pending;
  final bool inProgress;

  const ProcessingStep(this.number, this.title, this.subtitle, {required this.completed, this.pending = false, this.inProgress = false});
}

class ProcessingStepTile extends StatelessWidget {
  final ProcessingStep step;
  final bool isLast;
  const ProcessingStepTile({super.key, required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final Color textColor;
    final Color lineColor;

    if (step.completed) {
      textColor = AdminColors.darkText;
      lineColor = AdminColors.success.withOpacity(0.3);
    } else if (step.inProgress || step.pending) {
      textColor = AdminColors.primary;
      lineColor = AdminColors.border;
    } else {
      textColor = AdminColors.greyText;
      lineColor = AdminColors.border;
    }

    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: step.completed
                  ? AdminColors.success
                  : (step.inProgress || step.pending)
                  ? AdminColors.primary.withOpacity(0.12)
                  : AdminColors.greyText.withOpacity(0.10),
              shape: BoxShape.circle,
              border: Border.all(
                  color: step.completed
                      ? AdminColors.success
                      : (step.inProgress || step.pending)
                      ? AdminColors.primary.withOpacity(0.4)
                      : AdminColors.greyText.withOpacity(0.3),
                  width: 1.5),
            ),
            child: step.completed
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : Center(
              child: Text('${step.number}',
                  style: TextStyle(
                      color: (step.inProgress || step.pending) ? AdminColors.primary : AdminColors.greyText,
                      fontWeight: FontWeight.w900,
                      fontSize: 11)),
            ),
          ),
          if (!isLast)
            Expanded(
              child: Container(
                  width: 2,
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(color: lineColor, borderRadius: BorderRadius.circular(2))),
            ),
        ]),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.title, style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 13.5)),
                const SizedBox(height: 3),
                Text(step.subtitle, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 11.5)),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

/// FIX (missing feature — fit everything without scrolling, on narrow
/// screens): a compact horizontal version of the steps list. Shows the 6
/// pipeline stages as small connected circles instead of a tall vertical
/// list, with the current stage's title as a single line of text below —
/// so it takes roughly the height of one line instead of six rows.
class StepsStripBar extends StatelessWidget {
  final List<ProcessingStep> steps;
  const StepsStripBar({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();

    final activeIndex = steps.indexWhere((s) => !s.completed);
    final currentLabel =
    activeIndex == -1 ? steps.last.title : steps[activeIndex].title;

    final rowChildren = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      final isCurrent = i == activeIndex;
      final Color color = step.completed
          ? AdminColors.success
          : isCurrent
          ? AdminColors.primary
          : AdminColors.greyText.withOpacity(0.35);

      rowChildren.add(Container(
        height: 22,
        width: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: step.completed ? AdminColors.success : AdminColors.white,
          border: Border.all(color: color, width: 1.6),
        ),
        child: step.completed
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
            : Text('${step.number}',
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10)),
      ));

      if (i != steps.length - 1) {
        rowChildren.add(Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            color: step.completed ? AdminColors.success : AdminColors.border,
          ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: rowChildren),
        const SizedBox(height: 8),
        Text(
          currentLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w800, fontSize: 12.5),
        ),
      ],
    );
  }
}

/// FIX (missing feature — live transparency): one event in the admin's
/// real-time draw feed. Either a winner being drawn + allocated a plot, or
/// (once the winner list is finalized) an applicant not selected this run.
class DrawFeedEntry {
  /// Draw order number (1, 2, 3...). 0 for "not selected" entries, since
  /// those aren't drawn one-by-one — they're everyone left over once
  /// winners are chosen.
  final int serial;
  final String applicantName;
  final String cnicMasked;
  final String? plotNumber;
  final bool isSelected;
  final DateTime time;

  const DrawFeedEntry({
    required this.serial,
    required this.applicantName,
    required this.cnicMasked,
    required this.plotNumber,
    required this.isSelected,
    required this.time,
  });
}

class DrawFeedTile extends StatelessWidget {
  final DrawFeedEntry entry;
  const DrawFeedTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = entry.isSelected ? AdminColors.success : AdminColors.rejected;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(entry.isSelected ? Icons.check_rounded : Icons.close_rounded, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.serial > 0
                      ? 'Draw #${entry.serial.toString().padLeft(4, '0')} — ${entry.applicantName}'
                      : entry.applicantName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w800, fontSize: 12.5),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.cnicMasked,
                  style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 10.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            entry.isSelected ? (entry.plotNumber ?? '—') : 'Not Selected',
            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class DottedRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    const dotCount = 52;
    for (int i = 0; i < dotCount; i++) {
      final angle = (i / dotCount) * 2 * math.pi;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      final opacity = i % 2 == 0 ? 0.30 : 0.12;
      canvas.drawCircle(Offset(x, y), 2.2, Paint()..color = Colors.white.withOpacity(opacity)..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ArcPainter extends CustomPainter {
  final double progress;
  ArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.white.withOpacity(0.12)
          ..strokeWidth = 12
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);

    if (progress <= 0) return;

    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = Colors.white.withOpacity(0.20)
          ..strokeWidth = 20
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 12
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant ArcPainter old) => old.progress != progress;
}