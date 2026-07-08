import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  final double radius;
  final bool glass;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color = AdminColors.white,
    this.radius = AdminColors.radius,
    this.glass = true,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: color.withOpacity(glass ? 0.96 : 1),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AdminColors.primary.withOpacity(0.06)),
      boxShadow: [
        BoxShadow(
          color: AdminColors.primary.withOpacity(0.08),
          blurRadius: 26,
          offset: const Offset(0, 14),
        ),
      ],
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          padding: padding,
          decoration: decoration,
          child: child,
        ),
      ),
    );
  }
}

class PremiumSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;

  const PremiumSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AdminColors.radius),
        boxShadow: [
          BoxShadow(
            color: AdminColors.primary.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          color: AdminColors.darkText,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search_rounded, color: AdminColors.primary),
          suffixIcon: IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.tune_rounded, color: AdminColors.greyText),
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onActionTap;

  const SectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AdminColors.darkText,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AdminColors.greyText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (actionText != null)
            TextButton(onPressed: onActionTap, child: Text(actionText!)),
        ],
      ),
    );
  }
}

class LuxuryIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool showBadge;

  const LuxuryIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AdminColors.white,
          borderRadius: BorderRadius.circular(17),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(17),
            child: Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                boxShadow: [
                  BoxShadow(
                    color: AdminColors.primary.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, color: AdminColors.darkText, size: 22),
            ),
          ),
        ),
        if (showBadge)
          Positioned(
            right: -1,
            top: -1,
            child: Container(
              height: 11,
              width: 11,
              decoration: BoxDecoration(
                color: AdminColors.rejected,
                shape: BoxShape.circle,
                border: Border.all(color: AdminColors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class PopupMenuRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const PopupMenuRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AdminColors.primary, size: 20),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            color: AdminColors.darkText,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusPill({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class GradientIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const GradientIconBox({super.key, required this.icon, this.color = AdminColors.primary, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(size * 0.36),
      ),
      child: Icon(icon, color: color, size: size * 0.48),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoRow({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          GradientIconBox(icon: icon, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AdminColors.greyText, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: AdminColors.darkText, fontSize: 14, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: PremiumCard(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 66,
                width: 66,
                decoration: BoxDecoration(
                  color: AdminColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AdminColors.primary, size: 32),
              ),
              const SizedBox(height: 14),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 8),
              Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, height: 1.4)),
              const SizedBox(height: 18),
              FilledButton(onPressed: onPressed, child: Text(buttonText)),
            ],
          ),
        ),
      ),
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
      children: const [
        SkeletonBox(height: 150),
        SizedBox(height: 14),
        SkeletonBox(height: 110),
        SizedBox(height: 14),
        SkeletonBox(height: 110),
        SizedBox(height: 14),
        SkeletonBox(height: 210),
      ],
    );
  }
}

class SkeletonBox extends StatefulWidget {
  final double height;
  const SkeletonBox({super.key, required this.height});

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.35, end: 0.82).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) => Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: AdminColors.white.withOpacity(_opacity.value),
          borderRadius: BorderRadius.circular(AdminColors.radius),
        ),
      ),
    );
  }
}

class FilterTabs extends StatelessWidget {
  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  const FilterTabs({super.key, required this.filters, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 43,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = filters[index];
          final active = item == selected;
          return ChoiceChip(
            selected: active,
            label: Text(item),
            onSelected: (_) => onSelected(item),
            selectedColor: AdminColors.primary,
            backgroundColor: AdminColors.white,
            labelStyle: TextStyle(
              color: active ? AdminColors.white : AdminColors.greyText,
              fontWeight: FontWeight.w900,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
              side: BorderSide(color: active ? AdminColors.primary : AdminColors.primary.withOpacity(0.08)),
            ),
          );
        },
      ),
    );
  }
}

class DocumentPreviewBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool verified;
  final VoidCallback onTap;

  const DocumentPreviewBox({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.verified,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = verified ? AdminColors.success : AdminColors.warning;
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          GradientIconBox(icon: icon, color: color, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
          ),
          StatusPill(label: verified ? 'Clean' : 'Review', color: color),
        ],
      ),
    );
  }
}

class MiniLineChart extends StatelessWidget {
  final List<double> values;
  final Color color;

  const MiniLineChart({super.key, required this.values, this.color = AdminColors.primary});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: _MiniLineChartPainter(values: values, color: color),
      ),
    );
  }
}

class _MiniLineChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;

  const _MiniLineChartPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxV = values.reduce(math.max) + 8;
    const minV = 0.0;
    final height = size.height - 22;
    final step = size.width / (values.length - 1);

    final grid = Paint()
      ..color = AdminColors.greyText.withOpacity(0.08)
      ..strokeWidth = 1;

    for (int i = 0; i < 4; i++) {
      final y = height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    Offset point(int i) {
      final normalized = (values[i] - minV) / (maxV - minV);
      return Offset(i * step, height - normalized * height);
    }

    final path = Path()..moveTo(point(0).dx, point(0).dy);
    final fill = Path()
      ..moveTo(point(0).dx, height)
      ..lineTo(point(0).dx, point(0).dy);

    for (int i = 1; i < values.length; i++) {
      final prev = point(i - 1);
      final current = point(i);
      final cx = (prev.dx + current.dx) / 2;
      path.cubicTo(cx, prev.dy, cx, current.dy, current.dx, current.dy);
      fill.cubicTo(cx, prev.dy, cx, current.dy, current.dx, current.dy);
    }

    fill.lineTo(size.width, height);
    fill.close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          colors: [color.withOpacity(0.24), color.withOpacity(0.02)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    for (int i = 0; i < values.length; i++) {
      final p = point(i);
      canvas.drawCircle(p, 5.5, Paint()..color = AdminColors.white);
      canvas.drawCircle(
        p,
        5.5,
        Paint()
          ..color = color
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniLineChartPainter oldDelegate) => oldDelegate.values != values || oldDelegate.color != color;
}
