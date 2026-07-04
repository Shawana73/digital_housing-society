import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';
import '../widgets/app_snack.dart';

class BallotingProcessingScreen extends StatefulWidget {
  final String schemeName;
  final String schemeSize;

  const BallotingProcessingScreen({
    super.key,
    required this.schemeName,
    required this.schemeSize,
  });

  @override
  State<BallotingProcessingScreen> createState() => _BallotingProcessingScreenState();
}

class _BallotingProcessingScreenState extends State<BallotingProcessingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnim;

  double _progress = 0.72;
  bool _isRunning = true;
  bool _isPaused = false;

  final List<_Step> _steps = [
    _Step('Initializing Balloting',        'Preparing system and data',      true,  true),
    _Step('Validating Eligible Applicants','Checking applicant eligibility',  true,  true),
    _Step('Shuffling Applicants Securely', 'Randomizing applicants list',    false, false),
    _Step('Selecting Successful Applicants','Based on available plots',       false, false, pending: true),
    _Step('Assigning Plot Numbers',        'Allocating plots to winners',    false, false, pending: true),
    _Step('Finalizing Results',            'Saving results and updating status', false, false, pending: true),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _rotateController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  void _start() {
    setState(() { _isRunning = true; _isPaused = false; _progress = 0.72; });
    showAdminSnack(context, 'Balloting started');
  }

  void _pause() {
    setState(() { _isPaused = true; _isRunning = false; });
    showAdminSnack(context, 'Balloting paused');
  }

  void _resume() {
    setState(() { _isPaused = false; _isRunning = true; });
    showAdminSnack(context, 'Balloting resumed');
  }

  void _stop() {
    setState(() { _isRunning = false; _isPaused = false; _progress = 0.0; });
    showAdminSnack(context, 'Balloting stopped');
  }

  void _complete() {
    setState(() { _progress = 1.0; _isRunning = false; });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/balloting-result');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      body: Column(children: [
        // ── Purple AppBar ──────────────────────────────────────────────
        Container(
          color: AdminColors.primary,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Running Balloting',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -.4)),
                    Text(
                      '${widget.schemeName} - ${widget.schemeSize}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ]),
                ),
                // Notification badge
                Stack(clipBehavior: Clip.none, children: [
                  Container(
                    height: 42, width: 42,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17)),
                    child: const Icon(Icons.notifications_rounded, color: AdminColors.darkText, size: 22),
                  ),
                  Positioned(right: -1, top: -1, child: Container(
                    height: 11, width: 11,
                    decoration: BoxDecoration(color: AdminColors.rejected, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                  )),
                ]),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: AdminColors.primaryGradient,
                      boxShadow: [BoxShadow(color: AdminColors.primary.withOpacity(0.22), blurRadius: 12, offset: const Offset(0, 5))]),
                  child: const CircleAvatar(radius: 18, backgroundColor: Colors.white,
                      child: Icon(Icons.person_rounded, color: AdminColors.primary)),
                ),
              ]),
            ),
          ),
        ),

        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            children: [
              // ── Circular progress hero ────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [const Color(0xFF5A30E8), const Color(0xFF7B4DFF), const Color(0xFF9C6BFF)],
                  ),
                ),
                child: Column(children: [
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, child) => Transform.scale(scale: _isRunning ? _pulseAnim.value : 1.0, child: child),
                    child: SizedBox(
                      height: 190, width: 190,
                      child: Stack(alignment: Alignment.center, children: [
                        // Outer dotted ring
                        AnimatedBuilder(
                          animation: _rotateController,
                          builder: (_, child) => Transform.rotate(
                            angle: _isRunning ? _rotateController.value * 2 * math.pi : 0,
                            child: child,
                          ),
                          child: CustomPaint(size: const Size(190, 190), painter: _DottedRingPainter()),
                        ),
                        // Progress arc
                        CustomPaint(
                          size: const Size(160, 160),
                          painter: _ArcPainter(progress: _progress),
                        ),
                        // Centre content
                        Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.casino_rounded, color: Colors.white, size: 36),
                          const SizedBox(height: 8),
                          if (_isRunning)
                            const Text('Running Balloting...', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 12)),
                          if (_isPaused)
                            const Text('Paused', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('${(_progress * 100).round()}%',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 30, letterSpacing: -.8)),
                        ]),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('This may take a few minutes',
                      style: TextStyle(color: Colors.white60, fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
              ),

              const SizedBox(height: 18),

              // ── Control buttons ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AdminColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: AdminColors.primary.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 10))],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _ControlBtn(icon: Icons.play_arrow_rounded,  label: 'Start',  color: AdminColors.success,  onTap: _start),
                  _ControlBtn(icon: Icons.pause_rounded,        label: 'Pause',  color: AdminColors.warning,  onTap: _pause),
                  _ControlBtn(icon: Icons.restart_alt_rounded,  label: 'Resume', color: AdminColors.primary,  onTap: _resume),
                  _ControlBtn(icon: Icons.stop_rounded,         label: 'Stop',   color: AdminColors.rejected, onTap: _stop),
                ]),
              ),

              const SizedBox(height: 18),

              // ── Step log ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AdminColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: AdminColors.primary.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 10))],
                ),
                child: Column(
                  children: List.generate(_steps.length, (i) {
                    return _StepTile(step: _steps[i], isLast: i == _steps.length - 1);
                  }),
                ),
              ),

              const SizedBox(height: 18),

              // ── Complete button ────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _complete,
                  icon: const Icon(Icons.emoji_events_rounded, size: 20),
                  label: const Text('Complete & View Results', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AdminColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── Trust footer ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AdminColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  const Icon(Icons.verified_user_rounded, color: AdminColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Secure  •  Transparent  •  Fair',
                        style: TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w800, fontSize: 12)),
                    const SizedBox(height: 3),
                    const Text('Our digital balloting system ensures complete fairness and transparency.',
                        style: TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 11, height: 1.4)),
                  ])),
                ]),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ControlBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          height: 54, width: 54,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withOpacity(0.30), blurRadius: 12, offset: const Offset(0, 5))]),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
      ]),
    );
  }
}

class _Step {
  final String title;
  final String subtitle;
  final bool completed;
  final bool active;
  final bool pending;
  _Step(this.title, this.subtitle, this.completed, this.active, {this.pending = false});
}

class _StepTile extends StatelessWidget {
  final _Step step;
  final bool isLast;
  const _StepTile({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = step.completed
        ? AdminColors.success
        : step.pending
        ? AdminColors.primary
        : AdminColors.greyText;

    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(
            height: 28, width: 28,
            decoration: BoxDecoration(
              color: step.completed ? AdminColors.success : color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: step.completed
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : Center(child: Text('${_getStepNum()}',
                style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11))),
          ),
          if (!isLast)
            Expanded(child: Container(width: 2, color: AdminColors.border)),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(step.title,
                  style: TextStyle(
                      color: step.completed ? AdminColors.darkText : color,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5)),
              const SizedBox(height: 2),
              Text(step.subtitle,
                  style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 11.5)),
            ]),
          ),
        ),
      ]),
    );
  }

  int _getStepNum() {
    return 1; // placeholder; index is managed by parent
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom painters
// ─────────────────────────────────────────────────────────────────────────────

class _DottedRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const dotCount = 48;
    final paint = Paint()..color = Colors.white.withOpacity(0.25)..style = PaintingStyle.fill;
    for (int i = 0; i < dotCount; i++) {
      final angle = (i / dotCount) * 2 * math.pi;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 2.5, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArcPainter extends CustomPainter {
  final double progress;
  _ArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) => old.progress != progress;
}