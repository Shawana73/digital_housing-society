import 'package:flutter/material.dart';

/// Batch 3 presentation-only primitives. These widgets do not load or mutate
/// Firestore data; each screen supplies its own real state and callbacks.
class DhsContentWidth extends StatelessWidget {
  const DhsContentWidth({super.key, required this.child, this.maxWidth = 1000});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}

class DhsPageBanner extends StatelessWidget {
  const DhsPageBanner({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.footer,
    this.color = const Color(0xFF4B22D1),
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? footer;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 23),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, const Color(0xFF7C4DFF)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(eyebrow.toUpperCase(), style: const TextStyle(
                    color: Color(0xFFE4D9FF), fontWeight: FontWeight.w800,
                    fontSize: 11, letterSpacing: 1.2,
                  )),
                  const SizedBox(height: 8),
                  Text(title, style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800,
                    fontSize: 25, height: 1.12,
                  )),
                  const SizedBox(height: 9),
                  Text(subtitle, style: const TextStyle(
                    color: Color(0xFFF2ECFF), fontSize: 13.5, height: 1.45,
                  )),
                  if (footer != null) ...[
                    const SizedBox(height: 16),
                    footer!,
                  ],
                ],
              ),
            ),
            const SizedBox(width: 13),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: Colors.white24),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
          ],
        ),
      );
}

class DhsSection extends StatelessWidget {
  const DhsSection({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.icon,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE7E0F3)),
          boxShadow: [BoxShadow(
            color: const Color(0xFF5432AB).withValues(alpha: .045),
            blurRadius: 24, offset: const Offset(0, 8),
          )],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EEFF),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, size: 19, color: const Color(0xFF6743BC)),
                  ),
                  const SizedBox(width: 11),
                ],
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title!, style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 17,
                      color: Color(0xFF28203A),
                    )),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(subtitle!, style: const TextStyle(
                        color: Color(0xFF736A81), fontSize: 12.5, height: 1.35,
                      )),
                    ],
                  ],
                )),
              ]),
              const SizedBox(height: 18),
            ],
            child,
          ],
        ),
      );
}

class DhsInfoBox extends StatelessWidget {
  const DhsInfoBox({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.background = const Color(0xFFF8F6FD),
  });
  final String label;
  final String value;
  final IconData? icon;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEBE5F5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: const Color(0xFF785CB2)),
                const SizedBox(width: 5),
              ],
              Expanded(child: Text(label, style: const TextStyle(
                color: Color(0xFF756C84), fontSize: 12,
              ))),
            ]),
            const SizedBox(height: 7),
            SelectableText(value.trim().isEmpty ? 'Not available' : value,
              style: const TextStyle(color: Color(0xFF28203A),
                fontSize: 14, fontWeight: FontWeight.w700, height: 1.35)),
          ],
        ),
      );
}

/// Natural-height tiles; wraps instead of fixed grid cell heights, so long
/// names / CNIC labels / translated text stay readable on narrow screens.
class DhsDetailWrap extends StatelessWidget {
  const DhsDetailWrap({super.key, required this.children, this.twoColumnAt = 600});
  final List<Widget> children;
  final double twoColumnAt;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final twoColumns = constraints.maxWidth >= twoColumnAt;
          const gap = 11.0;
          final width = twoColumns
              ? (constraints.maxWidth - gap) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [for (final child in children) SizedBox(width: width, child: child)],
          );
        },
      );
}
