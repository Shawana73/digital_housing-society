import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../app_routes.dart';
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
  State<BallotingProcessingScreen> createState() =>
      _BallotingProcessingScreenState();
}

class _BallotingProcessingScreenState
    extends State<BallotingProcessingScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnim;

  double _progress = 0.72;
  bool _isRunning = true;
  bool _isPaused = false;

  // Each step: title, subtitle, stepNumber, completed, pending
  late List<_Step> _steps;

  @override
  void initState() {
    super.initState();
    _steps = [
      const _Step(1, 'Initializing Balloting',         'Preparing system and data',         completed: true),
      const _Step(2, 'Validating Eligible Applicants',  'Checking applicant eligibility',    completed: true),
      const _Step(3, 'Shuffling Applicants Securely',   'Randomizing applicants list',       completed: false, pending: true,  inProgress: true),
      const _Step(4, 'Selecting Successful Applicants', 'Based on available plots',          completed: false, pending: true),
      const _Step(5, 'Assigning Plot Numbers',          'Allocating plots to winners',       completed: false, pending: true),
      const _Step(6, 'Finalizing Results',              'Saving results and updating status',completed: false, pending: true),
    ];

    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _rotateController =
    AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
    _pulseAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
      _progress = 0.72;
    });
    showAdminSnack(context, 'Balloting started');
  }

  void _pause() {
    setState(() {
      _isPaused = true;
      _isRunning = false;
    });
    showAdminSnack(context, 'Balloting paused');
  }

  void _resume() {
    setState(() {
      _isPaused = false;
      _isRunning = true;
    });
    showAdminSnack(context, 'Balloting resumed');
  }

  void _stop() {
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _progress = 0.0;
    });
    showAdminSnack(context, 'Balloting stopped');
  }

  void _complete() {
    setState(() {
      _progress = 1.0;
      _isRunning = false;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AdminRoutes.results);
      }
    });
  }

  String get _statusLabel {
    if (_isPaused) return 'Paused';
    if (_isRunning) return 'Running...';
    if (_progress == 0) return 'Stopped';
    return 'Ready';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      body: Column(children: [
        // ── Purple AppBar ────────────────────────────────────────────────
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
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: -.4)),
                    Text(
                      '${widget.schemeName} - ${widget.schemeSize}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                    ),
                  ]),
                ),
                Stack(clipBehavior: Clip.none, children: [
                  Container(
                    height: 42, width: 42,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(17)),
                    child: const Icon(Icons.notifications_rounded,
                        color: AdminColors.darkText, size: 22),
                  ),
                  Positioned(
                    right: -1, top: -1,
                    child: Container(
                      height: 11, width: 11,
                      decoration: BoxDecoration(
                          color: AdminColors.rejected,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2)),
                    ),
                  ),
                ]),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AdminColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                            color: AdminColors.primary.withOpacity(0.22),
                            blurRadius: 12,
                            offset: const Offset(0, 5))
                      ]),
                  child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person_rounded,
                          color: AdminColors.primary)),
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

              // ── Circular progress hero ──────────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF5A30E8), Color(0xFF7B4DFF), Color(0xFF9C6BFF)],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
                child: Column(children: [
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, child) => Transform.scale(
                      scale: _isRunning ? _pulseAnim.value : 1.0,
                      child: child,
                    ),
                    child: SizedBox(
                      height: 200, width: 200,
                      child: Stack(alignment: Alignment.center, children: [
                        // Outer rotating dotted ring
                        AnimatedBuilder(
                          animation: _rotateController,
                          builder: (_, child) => Transform.rotate(
                            angle: _isRunning
                                ? _rotateController.value * 2 * math.pi
                                : 0,
                            child: child,
                          ),
                          child: CustomPaint(
                              size: const Size(200, 200),
                              painter: _DottedRingPainter()),
                        ),
                        // Glow ring (static soft glow)
                        Container(
                          height: 168, width: 168,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.white.withOpacity(0.08),
                                  blurRadius: 24,
                                  spreadRadius: 4)
                            ],
                          ),
                        ),
                        // Progress arc
                        CustomPaint(
                          size: const Size(168, 168),
                          painter: _ArcPainter(progress: _progress),
                        ),
                        // Centre content
                        Column(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            height: 44, width: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.casino_rounded,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(height: 6),
                          Text(_statusLabel,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                          Text('${(_progress * 100).round()}%',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 34,
                                  letterSpacing: -1)),
                        ]),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 6,
                      backgroundColor: Colors.white.withOpacity(0.18),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('This may take a few minutes',
                      style: TextStyle(
                          color: Colors.white60,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ]),
              ),

              const SizedBox(height: 16),

              // ── Control buttons ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: AdminColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: AdminColors.primary.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 10))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ControlBtn(icon: Icons.play_arrow_rounded,  label: 'Start',  color: AdminColors.success,  onTap: _start),
                    _ControlBtn(icon: Icons.pause_rounded,        label: 'Pause',  color: AdminColors.warning,  onTap: _pause),
                    _ControlBtn(icon: Icons.restart_alt_rounded,  label: 'Resume', color: AdminColors.primary,  onTap: _resume),
                    _ControlBtn(icon: Icons.stop_rounded,         label: 'Stop',   color: AdminColors.rejected, onTap: _stop),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Step log ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AdminColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: AdminColors.primary.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 10))
                  ],
                ),
                child: Column(
                  children: _steps.asMap().entries.map((e) {
                    return _StepTile(
                      step: e.value,
                      isLast: e.key == _steps.length - 1,
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // ── Complete button ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _complete,
                  icon: const Icon(Icons.emoji_events_rounded, size: 20),
                  label: const Text('Complete & View Results',
                      style:
                      TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AdminColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── Trust footer ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AdminColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  Container(
                    height: 42, width: 42,
                    decoration: BoxDecoration(
                      color: AdminColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.verified_user_rounded,
                        color: AdminColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Secure  •  Transparent  •  Fair',
                              style: TextStyle(
                                  color: AdminColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12)),
                          SizedBox(height: 3),
                          Text(
                              'Our digital balloting system ensures complete fairness and transparency.',
                              style: TextStyle(
                                  color: AdminColors.greyText,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  height: 1.4)),
                        ]),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Control button
// ─────────────────────────────────────────────────────────────────────────────

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ControlBtn(
      {required this.icon,
        required this.label,
        required this.color,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          height: 58, width: 58,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.32),
                  blurRadius: 14,
                  offset: const Offset(0, 6))
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 7),
        Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 12)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step model + tile
// ─────────────────────────────────────────────────────────────────────────────

class _Step {
  final int number;
  final String title;
  final String subtitle;
  final bool completed;
  final bool pending;
  final bool inProgress; // currently running — purple with spinning indicator

  const _Step(this.number, this.title, this.subtitle,
      {required this.completed, this.pending = false, this.inProgress = false});
}

class _StepTile extends StatelessWidget {
  final _Step step;
  final bool isLast;
  const _StepTile({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    // Color logic:
    // completed   → green circle with checkmark, dark text
    // inProgress  → purple circle with number, purple text (currently running)
    // pending     → purple circle with number, purple text (queued)
    // else        → grey circle with number, grey text

    final Color circleColor;
    final Color textColor;
    final Color lineColor;

    if (step.completed) {
      circleColor = AdminColors.success;
      textColor   = AdminColors.darkText;
      lineColor   = AdminColors.success.withOpacity(0.3);
    } else if (step.inProgress || step.pending) {
      circleColor = AdminColors.primary;
      textColor   = AdminColors.primary;
      lineColor   = AdminColors.border;
    } else {
      circleColor = AdminColors.greyText.withOpacity(0.4);
      textColor   = AdminColors.greyText;
      lineColor   = AdminColors.border;
    }

    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(
            height: 30, width: 30,
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
                      color: (step.inProgress || step.pending)
                          ? AdminColors.primary
                          : AdminColors.greyText,
                      fontWeight: FontWeight.w900,
                      fontSize: 11)),
            ),
          ),
          if (!isLast)
            Expanded(
              child: Container(
                  width: 2,
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                      color: lineColor,
                      borderRadius: BorderRadius.circular(2))),
            ),
        ]),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title,
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5)),
                  const SizedBox(height: 3),
                  Text(step.subtitle,
                      style: const TextStyle(
                          color: AdminColors.greyText,
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5)),
                ]),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom painters
// ─────────────────────────────────────────────────────────────────────────────

class _DottedRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    const dotCount = 52;
    for (int i = 0; i < dotCount; i++) {
      final angle = (i / dotCount) * 2 * math.pi;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      // Alternating opacity for a dashed feel
      final opacity = i % 2 == 0 ? 0.30 : 0.12;
      canvas.drawCircle(
          Offset(x, y),
          2.2,
          Paint()
            ..color = Colors.white.withOpacity(opacity)
            ..style = PaintingStyle.fill);
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
    final radius = size.width / 2 - 8;

    // Track
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.white.withOpacity(0.12)
          ..strokeWidth = 12
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);

    if (progress <= 0) return;

    // Glow pass (wider, faint)
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

    // Main arc
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
  bool shouldRepaint(covariant _ArcPainter old) => old.progress != progress;
}
