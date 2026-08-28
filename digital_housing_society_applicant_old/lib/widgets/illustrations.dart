import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class IllustrationBox extends StatelessWidget {
  const IllustrationBox({super.key, required this.painter, this.height = 150, this.backgroundColor});
  final CustomPainter painter;
  final double height;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.lightPurpleBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: CustomPaint(painter: painter),
    );
  }
}

class HousingLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = Paint()
      ..shader = AppColors.primaryGradient.createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(18), const Radius.circular(28)), bg);
    final white = Paint()..color = AppColors.white;
    final gold = Paint()..color = AppColors.gold;
    final center = Offset(size.width / 2, size.height / 2 + 8);
    final roof = Path()
      ..moveTo(center.dx - 48, center.dy - 8)
      ..lineTo(center.dx, center.dy - 54)
      ..lineTo(center.dx + 48, center.dy - 8)
      ..close();
    canvas.drawPath(roof, white);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(center.dx, center.dy + 22), width: 78, height: 62), const Radius.circular(12)), white);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(center.dx, center.dy + 32), width: 22, height: 42), const Radius.circular(6)), Paint()..color = AppColors.deepPurple);
    canvas.drawCircle(Offset(center.dx + 58, center.dy - 52), 6, gold);
    canvas.drawCircle(Offset(center.dx - 64, center.dy + 52), 4, gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CitySkylinePainter extends CustomPainter {
  CitySkylinePainter({this.light = false});
  final bool light;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = light ? AppColors.lavender.withValues(alpha: 0.35) : AppColors.deepPurple.withValues(alpha: 0.45);
    final moon = Paint()..color = AppColors.gold.withValues(alpha: 0.85);
    canvas.drawCircle(Offset(size.width - 45, 34), 12, moon);
    for (var i = 0; i < 18; i++) {
      final x = i * size.width / 17;
      canvas.drawCircle(Offset(x, 18 + (i % 3) * 18), 1.6, Paint()..color = AppColors.white.withValues(alpha: 0.55));
    }
    final ground = size.height - 12;
    for (var i = 0; i < 8; i++) {
      final w = 28 + (i % 3) * 12.0;
      final h = 45 + (i % 4) * 18.0;
      final x = i * (size.width / 7.5);
      final rect = Rect.fromLTWH(x, ground - h, w, h);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), paint);
      for (var yy = rect.top + 10; yy < rect.bottom - 8; yy += 14) {
        canvas.drawRect(Rect.fromLTWH(rect.left + 8, yy, 5, 5), Paint()..color = AppColors.gold.withValues(alpha: 0.75));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FolderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = AppColors.primaryPurple.withValues(alpha: 0.92);
    final dark = Paint()..color = AppColors.deepPurple;
    final x = size.width / 2 - 62;
    final y = size.height / 2 - 42;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 62, 24), const Radius.circular(8)), dark);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y + 14, 128, 78), const Radius.circular(18)), p);
    canvas.drawPath(Path()..moveTo(x + 18, y + 42)..lineTo(x + 64, y + 72)..lineTo(x + 110, y + 42), Paint()..color = AppColors.white.withValues(alpha: 0.75)..style = PaintingStyle.stroke..strokeWidth = 7..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DocumentCheckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * .5, size.height * .5);
    final doc = Rect.fromCenter(center: c, width: 90, height: 116);
    canvas.drawRRect(RRect.fromRectAndRadius(doc, const Radius.circular(16)), Paint()..color = AppColors.white.withValues(alpha: .95));
    canvas.drawRRect(RRect.fromRectAndRadius(doc, const Radius.circular(16)), Paint()..color = AppColors.lavender..style = PaintingStyle.stroke..strokeWidth = 3);
    for (var i = 0; i < 4; i++) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(doc.left + 18, doc.top + 26 + i * 18, 54, 5), const Radius.circular(9)), Paint()..color = AppColors.lavender);
    }
    canvas.drawCircle(Offset(c.dx + 46, c.dy + 46), 26, Paint()..color = AppColors.successGreen);
    canvas.drawPath(Path()..moveTo(c.dx + 34, c.dy + 45)..lineTo(c.dx + 44, c.dy + 55)..lineTo(c.dx + 61, c.dy + 34), Paint()..color = AppColors.white..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CnicCardPainter extends CustomPainter {
  CnicCardPainter({this.uploaded = false});
  final bool uploaded;

  @override
  void paint(Canvas canvas, Size size) {
    final card = Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: size.width * .72, height: size.height * .54);
    canvas.drawRRect(RRect.fromRectAndRadius(card, const Radius.circular(18)), Paint()..color = uploaded ? AppColors.successLightBackground : AppColors.white);
    final borderPaint = Paint()
      ..color = uploaded ? AppColors.successGreen : AppColors.primaryPurple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(RRect.fromRectAndRadius(card, const Radius.circular(18)), borderPaint);
    canvas.drawCircle(Offset(card.left + 30, card.top + 36), 15, Paint()..color = AppColors.lavender);
    for (var i = 0; i < 3; i++) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(card.left + 60, card.top + 26 + i * 17, card.width - 88, 6), const Radius.circular(8)), Paint()..color = AppColors.lavender.withValues(alpha: .8));
    }
    if (uploaded) {
      canvas.drawCircle(Offset(card.right - 20, card.top + 20), 18, Paint()..color = AppColors.successGreen);
      canvas.drawPath(Path()..moveTo(card.right - 29, card.top + 20)..lineTo(card.right - 20, card.top + 29)..lineTo(card.right - 8, card.top + 12), Paint()..color = AppColors.white..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant CnicCardPainter oldDelegate) => oldDelegate.uploaded != uploaded;
}

class ReceiptPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: 86, height: 112);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)), Paint()..color = AppColors.white);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)), Paint()..color = AppColors.gold..style = PaintingStyle.stroke..strokeWidth = 3);
    for (var i = 0; i < 5; i++) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(rect.left + 18, rect.top + 24 + i * 15, 50, 5), const Radius.circular(8)), Paint()..color = i == 4 ? AppColors.warningOrange : AppColors.lavender);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TrophyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final gold = Paint()..color = AppColors.gold;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: 70, height: 78), const Radius.circular(22)), gold);
    canvas.drawArc(Rect.fromCenter(center: Offset(c.dx - 40, c.dy - 2), width: 46, height: 46), -math.pi / 2, math.pi, false, Paint()..color = AppColors.gold..style = PaintingStyle.stroke..strokeWidth = 8);
    canvas.drawArc(Rect.fromCenter(center: Offset(c.dx + 40, c.dy - 2), width: 46, height: 46), math.pi / 2, math.pi, false, Paint()..color = AppColors.gold..style = PaintingStyle.stroke..strokeWidth = 8);
    canvas.drawRect(Rect.fromCenter(center: Offset(c.dx, c.dy + 52), width: 20, height: 34), gold);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(c.dx, c.dy + 76), width: 88, height: 18), const Radius.circular(9)), gold);
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8;
      canvas.drawCircle(Offset(c.dx + math.cos(a) * 82, c.dy + math.sin(a) * 58), 2.5, Paint()..color = i.isEven ? AppColors.primaryPurple : AppColors.successGreen);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MagnifierPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2 - 12, size.height / 2 - 8);
    canvas.drawCircle(c, 42, Paint()..color = AppColors.white..style = PaintingStyle.fill);
    canvas.drawCircle(c, 42, Paint()..color = AppColors.primaryPurple..style = PaintingStyle.stroke..strokeWidth = 8);
    canvas.drawLine(Offset(c.dx + 31, c.dy + 31), Offset(c.dx + 72, c.dy + 72), Paint()..color = AppColors.deepPurple..strokeWidth = 10..strokeCap = StrokeCap.round);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: 54, height: 34), const Radius.circular(8)), Paint()..color = AppColors.lightPurpleBackground);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LotteryDrumPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2 + 8);
    canvas.drawOval(Rect.fromCenter(center: c, width: 135, height: 86), Paint()..color = AppColors.lavender.withValues(alpha: .85));
    canvas.drawOval(Rect.fromCenter(center: c, width: 135, height: 86), Paint()..color = AppColors.gold..style = PaintingStyle.stroke..strokeWidth = 5);
    for (var i = 0; i < 8; i++) {
      canvas.drawCircle(Offset(c.dx - 44 + i * 13, c.dy - 8 + (i % 3) * 11), 8, Paint()..color = [AppColors.gold, AppColors.white, AppColors.primaryPurple][i % 3]);
    }
    canvas.drawLine(Offset(c.dx - 76, c.dy + 52), Offset(c.dx + 76, c.dy + 52), Paint()..color = AppColors.gold..strokeWidth = 5..strokeCap = StrokeCap.round);
    canvas.drawLine(Offset(c.dx - 60, c.dy + 52), Offset(c.dx - 88, c.dy + 84), Paint()..color = AppColors.gold..strokeWidth = 5..strokeCap = StrokeCap.round);
    canvas.drawLine(Offset(c.dx + 60, c.dy + 52), Offset(c.dx + 88, c.dy + 84), Paint()..color = AppColors.gold..strokeWidth = 5..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
