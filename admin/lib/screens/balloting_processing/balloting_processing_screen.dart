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
  final String schemeId;
  final DateTime? schemeDate;

  const BallotingProcessingScreen({
    super.key,
    required this.schemeName,
    required this.schemeSize,
    required this.schemeId,
    this.schemeDate,
  });

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

  String _formatScheduledDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _start() async {
    if (widget.schemeDate != null && DateTime.now().isBefore(widget.schemeDate!)) {
      showAdminSnack(
        context,
        'This balloting is scheduled for ${_formatScheduledDate(widget.schemeDate!)}. '
            'It cannot be started early.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AdminColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminColors.radius),
        ),
        title: const Text(
          'Start Balloting?',
          style: TextStyle(
            color: AdminColors.darkText,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          'You are about to start the official balloting for '
              '${widget.schemeName} (${widget.schemeSize}).\n\n'
              'This action will select eligible applicants and allocate available plots.',
          style: const TextStyle(
            color: AdminColors.greyText,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.primary,
            ),
            child: const Text('Start Balloting'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final success = await _viewModel.start(
      schemeName: widget.schemeName,
      schemeSize: widget.schemeSize,
      schemeId: widget.schemeId,
      scheduledDate: widget.schemeDate,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Balloting completed successfully.'),
        ),
      );

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        AdminRoutes.results,
        arguments: {
          'schemeId': widget.schemeId,
          'schemeName': widget.schemeName,
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _viewModel.errorMessage ?? 'Balloting failed.',
          ),
        ),
      );
    }
  }

  Future<void> _pause() async {
    await _viewModel.pause();
    if (!mounted) return;
    showAdminSnack(context, 'Balloting paused');
  }

  Future<void> _resume() async {
    await _viewModel.resume();
    if (!mounted) return;
    showAdminSnack(context, 'Balloting resumed');
  }

  void _stop() {
    _viewModel.stop();
    showAdminSnack(context, 'Balloting stopped');
  }

  void _complete() {
    if (_viewModel.progress < 1.0 || _viewModel.isProcessing) {
      showAdminSnack(context, 'Please complete the balloting first');
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      AdminRoutes.results,
      arguments: {
        'schemeId': widget.schemeId,
        'schemeName': widget.schemeName,
      },
    );
  }

  // ============================================================
  // REUSABLE PIECES — shared between the wide (web/tablet) layout and
  // the compact (mobile) layout, so both stay visually consistent.
  // ============================================================

  Widget _buildTopBar(BuildContext context) {
    return Container(
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
    );
  }

  /// [compact] shrinks the ring, hides the "This may take a few minutes"
  /// caption, and tightens padding — used on narrow (mobile) screens so
  /// everything else still fits without scrolling.
  Widget _buildProgressHero({required bool compact}) {
    final progress = _viewModel.progress;
    final isRunning = _viewModel.isRunning;

    final ringSize = compact ? 120.0 : 200.0;
    final innerSize = compact ? 100.0 : 168.0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5A30E8), Color(0xFF7B4DFF), Color(0xFF9C6BFF)],
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, compact ? 18 : 32, 16, compact ? 18 : 32),
      child: Column(children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, child) => Transform.scale(scale: isRunning ? _pulseAnim.value : 1.0, child: child),
          child: SizedBox(
            height: ringSize,
            width: ringSize,
            child: Stack(alignment: Alignment.center, children: [
              AnimatedBuilder(
                animation: _rotateController,
                builder: (_, child) => Transform.rotate(angle: isRunning ? _rotateController.value * 2 * math.pi : 0, child: child),
                child: CustomPaint(size: Size(ringSize, ringSize), painter: DottedRingPainter()),
              ),
              Container(
                height: innerSize,
                width: innerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.08), blurRadius: 24, spreadRadius: 4)],
                ),
              ),
              CustomPaint(size: Size(innerSize, innerSize), painter: ArcPainter(progress: progress)),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  height: compact ? 30 : 44,
                  width: compact ? 30 : 44,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle),
                  child: Icon(Icons.casino_rounded, color: Colors.white, size: compact ? 15 : 24),
                ),
                SizedBox(height: compact ? 3 : 6),
                Text(_viewModel.statusLabel,
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: compact ? 10 : 12)),
                Text('${(progress * 100).round()}%',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: compact ? 22 : 34, letterSpacing: -1)),
              ]),
            ]),
          ),
        ),
        SizedBox(height: compact ? 10 : 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.white.withOpacity(0.18),
            color: Colors.white,
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 12),
          const Text('This may take a few minutes', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ]),
    );
  }

  Widget _buildControlsCard({bool compact = false}) {
    final isProcessing = _viewModel.isProcessing;
    final isPaused = _viewModel.isPaused;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: compact ? 12 : 20),
      decoration: BoxDecoration(
        color: AdminColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AdminColors.primary.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ProcessingControlBtn(
            icon: Icons.play_arrow_rounded,
            label: 'Start',
            color: AdminColors.success,
            onTap: _start,
            enabled: !isProcessing,
          ),
          ProcessingControlBtn(
            icon: Icons.pause_rounded,
            label: 'Pause',
            color: AdminColors.warning,
            onTap: _pause,
            enabled: isProcessing && !isPaused,
          ),
          ProcessingControlBtn(
            icon: Icons.restart_alt_rounded,
            label: 'Resume',
            color: AdminColors.primary,
            onTap: _resume,
            enabled: isPaused,
          ),
          ProcessingControlBtn(
            icon: Icons.stop_rounded,
            label: 'Stop',
            color: AdminColors.rejected,
            onTap: _stop,
            enabled: isProcessing,
          ),
        ],
      ),
    );
  }

  /// Full vertical steps list — used on wide screens where there's room.
  Widget _buildStepsCard() {
    return Container(
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
    );
  }

  /// Compact horizontal steps strip — used on narrow (mobile) screens so
  /// the pipeline stages still show, without costing six rows of height.
  Widget _buildStepsStripCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AdminColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AdminColors.primary.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: StepsStripBar(steps: _viewModel.steps),
    );
  }

  /// [expand]=true makes the feed's inner list fill all remaining space
  /// via Expanded (used inside a non-scrolling Column on mobile).
  /// [expand]=false gives it a fixed height instead (used inside a
  /// scrollable ListView / side-by-side Row on wide screens).
  Widget _buildLiveFeedCard(List<DrawFeedEntry> feed, {bool expand = false, double fixedHeight = 280}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AdminColors.primary.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.shuffle_rounded, color: AdminColors.primary, size: 18),
              const SizedBox(width: 8),
              const Text('Live Draw Feed',
                  style: TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 15)),
              const Spacer(),
              if (feed.isNotEmpty)
                Text('${feed.length}',
                    style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w700, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'See exactly which applicants are being shuffled, selected, and allocated plots — as it happens.',
            style: TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 12),
          if (feed.isEmpty)
            expand
                ? const Expanded(
              child: Center(
                child: Text(
                  'No draws yet. Start the balloting to see live activity here.',
                  style: TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            )
                : const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No draws yet. Start the balloting to see live activity here.',
                  style: TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            )
          else if (expand)
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: feed.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AdminColors.border),
                itemBuilder: (context, index) => DrawFeedTile(entry: feed[index]),
              ),
            )
          else
            SizedBox(
              height: fixedHeight,
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: feed.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AdminColors.border),
                itemBuilder: (context, index) => DrawFeedTile(entry: feed[index]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompleteButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _viewModel.progress == 1.0 && !_viewModel.isProcessing ? _complete : null,
        icon: const Icon(Icons.emoji_events_rounded, size: 20),
        label: const Text('Complete & View Results', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
        style: FilledButton.styleFrom(
          backgroundColor: AdminColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildSecureFooter() {
    return Container(
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
    );
  }

  // ============================================================
  // LAYOUTS
  // ============================================================

  /// Web / tablet: everything in a scrollable column, but Steps and Live
  /// Feed sit side by side (not stacked), so there's usually little or no
  /// scrolling needed even with the full-size progress ring.
  Widget _buildWideLayout() {
    final feed = _viewModel.drawFeed.reversed.toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            _buildProgressHero(compact: false),
            const SizedBox(height: 16),
            _buildControlsCard(),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildStepsCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildLiveFeedCard(feed, fixedHeight: 420)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildCompleteButton(),
            const SizedBox(height: 14),
            _buildSecureFooter(),
          ],
        ),
      ),
    );
  }

  /// Mobile: a non-scrolling Column sized to the available height. The
  /// progress ring and steps strip are compact, and the Live Draw Feed
  /// expands to fill whatever space is left — so the ring, the pipeline
  /// stage, and live activity are all visible together without scrolling.
  Widget _buildCompactLayout() {
    final feed = _viewModel.drawFeed.reversed.toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: _buildProgressHero(compact: true),
          ),
          const SizedBox(height: 10),
          _buildControlsCard(compact: true),
          const SizedBox(height: 10),
          _buildStepsStripCard(),
          const SizedBox(height: 10),
          Expanded(child: _buildLiveFeedCard(feed, expand: true)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AdminColors.background,
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: isWide ? _buildWideLayout() : _buildCompactLayout(),
          ),
        ],
      ),
    );
  }
}