import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../theme/admin_theme.dart';

class ResultCelebrationHero extends StatelessWidget {
  const ResultCelebrationHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AdminColors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: AdminColors.primary.withOpacity(0.10), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            final cx = w / 2;
            const h = 140.0;
            final confetti = [
              (Colors.yellow, cx - 110, 22.0, 11.0, 10.0, 0.5),
              (Colors.pink, cx - 90, 55.0, 9.0, 12.0, -0.4),
              (Colors.cyan, cx - 120, 80.0, 8.0, 13.0, 0.6),
              (Colors.orange, cx - 70, 12.0, 10.0, 9.0, -0.3),
              (Colors.green, cx + 100, 18.0, 11.0, 10.0, -0.5),
              (Colors.red, cx + 80, 58.0, 9.0, 12.0, 0.4),
              (Colors.blue, cx + 112, 82.0, 8.0, 11.0, -0.6),
              (Colors.purple, cx + 65, 10.0, 10.0, 9.0, 0.3),
              (Colors.amber, cx - 40, 8.0, 9.0, 7.0, -0.5),
              (Colors.teal, cx + 38, 6.0, 8.0, 9.0, 0.4),
              (const Color(0xFFFF6B6B), cx - 50, 105.0, 10.0, 7.0, 0.6),
              (const Color(0xFF4ECDC4), cx + 45, 108.0, 7.0, 10.0, -0.4),
              (Colors.indigo, cx - 100, 105.0, 9.0, 7.0, 0.3),
              (Colors.deepOrange, cx + 95, 105.0, 8.0, 9.0, -0.5),
            ];
            return SizedBox(
              height: h,
              width: w,
              child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
                ...confetti.map((c) {
                  final (color, x, y, cw, ch, angle) = c;
                  return Positioned(
                    left: x - cw / 2,
                    top: y,
                    child: Transform.rotate(
                      angle: angle,
                      child: Container(
                        width: cw,
                        height: ch,
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                  );
                }),
                Positioned(
                  left: cx - 52,
                  top: 18,
                  child: Container(
                    height: 104,
                    width: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AdminColors.success.withOpacity(0.08),
                      boxShadow: [BoxShadow(color: AdminColors.success.withOpacity(0.18), blurRadius: 28, spreadRadius: 6)],
                    ),
                  ),
                ),
                Positioned(
                  left: cx - 41,
                  top: 29,
                  child: Container(
                    height: 82,
                    width: 82,
                    decoration: BoxDecoration(
                      color: AdminColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AdminColors.success.withOpacity(0.38), blurRadius: 22, offset: const Offset(0, 8))],
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 46),
                  ),
                ),
              ]),
            );
          }),
          const SizedBox(height: 14),
          const Text('Balloting Completed!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -.5)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(color: AdminColors.primary.withOpacity(0.07), borderRadius: BorderRadius.circular(20)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.calendar_today_rounded, color: AdminColors.primary, size: 13),
              SizedBox(width: 7),
              Text('10 Jul 2026, 11:02 AM', style: TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
          ),
        ],
      ),
    );
  }
}

class ResultSummaryGrid extends StatelessWidget {
  const ResultSummaryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      ('Total', '1,284', AdminColors.primary, Icons.groups_rounded),
      ('Successful', '120', AdminColors.success, Icons.verified_rounded),
      ('Unsuccessful', '1,164', AdminColors.rejected, Icons.cancel_rounded),
      ('Success Rate', '9.3%', AdminColors.warning, Icons.percent_rounded),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tiles.asMap().entries.map((e) {
        final i = e.key;
        final (label, value, color, icon) = e.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AdminColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AdminColors.primary.withOpacity(0.07), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(height: 8),
                Text(label,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 9.0, height: 1.25)),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: -.3)),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class WinnerRow extends StatelessWidget {
  final int rank;
  final BallotingResult result;
  final bool isLast;
  const WinnerRow({super.key, required this.rank, required this.result, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(color: AdminColors.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(8)),
            child: Center(
              child: Text(rank.toString().padLeft(2, '0'),
                  style: const TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w900, fontSize: 11)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(result.applicantName,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 2),
            Text(result.cnic, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 10.5)),
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('Plot No.', style: TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 9.5)),
            const SizedBox(height: 1),
            Text(result.plotNo, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w800, fontSize: 12)),
          ]),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: result.selected ? AdminColors.success.withOpacity(0.12) : AdminColors.warning.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              result.selected ? 'Successful' : 'Not Selected',
              style: TextStyle(
                  color: result.selected ? AdminColors.success : AdminColors.warning, fontWeight: FontWeight.w800, fontSize: 9.5),
            ),
          ),
        ]),
      ),
      if (!isLast) Container(height: 1, color: AdminColors.border.withOpacity(0.6)),
    ]);
  }
}

class ResultSLabel extends StatelessWidget {
  final String text;
  const ResultSLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: -.3));
}