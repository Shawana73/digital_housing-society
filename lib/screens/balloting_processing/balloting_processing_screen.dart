import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app_routes.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/app_snack.dart';
import 'balloting_processing_viewmodel.dart';
import 'balloting_processing_widgets.dart';

class BallotingProcessingScreen extends StatefulWidget {
  final String schemeName;
  final String schemeSize;

  const BallotingProcessingScreen({super.key, required this.schemeName, required this.schemeSize});

  @override
  State<BallotingProcessingScreen> createState() => _BallotingProcessingScreenState();
}

class _BallotingProcessingScreenState extends State<BallotingProcessingScreen> with TickerProviderStateMixin {
  final BallotingProcessingViewModel _viewModel = BallotingProcessingViewModel();

  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_refresh);

    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _rotateController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _pulseAnim = Tween<double>(begin: 0.96, end: 1.04).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_refresh);
    _viewModel.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  void _start() {
    _viewModel.start();
    showAdminSnack(context, 'Balloting started');
  }

  void _pause() {
    _viewModel.pause();
    showAdminSnack(context, 'Balloting paused');
  }

  void _resume() {
    _viewModel.resume();
    showAdminSnack(context, 'Balloting resumed');
  }

  void _stop() {
    _viewModel.stop();
    showAdminSnack(context, 'Balloting stopped');
  }

  void _complete() {
    _viewModel.complete();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AdminRoutes.results);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = _viewModel.progress;
    final isRunning = _viewModel.isRunning;

    return Scaffold(
      backgroundColor: AdminColors.background,
      body: Column(children: [
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
                Stack(clipBehavior: Clip.none, children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17)),
                    child: const Icon(Icons.notifications_rounded, color: AdminColors.darkText, size: 22),
                  ),
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      height: 11,
                      width: 11,
                      decoration: BoxDecoration(color: AdminColors.rejected, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    ),
                  ),
                ]),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AdminColors.primaryGradient,
                      boxShadow: [BoxShadow(color: AdminColors.primary.withOpacity(0.22), blurRadius: 12, offset: const Offset(0, 5))]),
                  child: const CircleAvatar(radius: 18, backgroundColor: Colors.white, child: Icon(Icons.person_rounded, color: AdminColors.primary)),
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
                    builder: (_, child) => Transform.scale(scale: isRunning ? _pulseAnim.value : 1.0, child: child),
                    child: SizedBox(
                      height: 200,
                      width: 200,
                      child: Stack(alignment: Alignment.center, children: [
                        AnimatedBuilder(
                          animation: _rotateController,
                          builder: (_, child) => Transform.rotate(angle: isRunning ? _rotateController.value * 2 * math.pi : 0, child: child),
                          child: CustomPaint(size: const Size(200, 200), painter: DottedRingPainter()),
                        ),
                        Container(
                          height: 168,
                          width: 168,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.08), blurRadius: 24, spreadRadius: 4)],
                          ),
                        ),
                        CustomPaint(size: const Size(168, 168), painter: ArcPainter(progress: progress)),
                        Column(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle),
                            child: const Icon(Icons.casino_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(height: 6),
                          Text(_viewModel.statusLabel, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 12)),
                          Text('${(progress * 100).round()}%',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 34, letterSpacing: -1)),
                        ]),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.white.withOpacity(0.18),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('This may take a few minutes', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: AdminColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: AdminColors.primary.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 10))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ProcessingControlBtn(icon: Icons.play_arrow_rounded, label: 'Start', color: AdminColors.success, onTap: _start),
                    ProcessingControlBtn(icon: Icons.pause_rounded, label: 'Pause', color: AdminColors.warning, onTap: _pause),
                    ProcessingControlBtn(icon: Icons.restart_alt_rounded, label: 'Resume', color: AdminColors.primary, onTap: _resume),
                    ProcessingControlBtn(icon: Icons.stop_rounded, label: 'Stop', color: AdminColors.rejected, onTap: _stop),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AdminColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: AdminColors.primary.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 10))],
                ),
                child: Column(
                  children: _viewModel.steps.asMap().entries.map((e) {
                    return ProcessingStepTile(step: e.value, isLast: e.key == _viewModel.steps.length - 1);
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AdminColors.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(color: AdminColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.verified_user_rounded, color: AdminColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Secure  •  Transparent  •  Fair',
                            style: TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w800, fontSize: 12)),
                        SizedBox(height: 3),
                        Text('Our digital balloting system ensures complete fairness and transparency.',
                            style: TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 11, height: 1.4)),
                      ],
                    ),
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