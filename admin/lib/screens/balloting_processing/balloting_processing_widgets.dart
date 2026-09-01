import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/admin_theme.dart';

class ProcessingControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const ProcessingControlBtn({super.key, required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          height: 58,
          width: 58,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withOpacity(0.32), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 7),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
      ]),
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