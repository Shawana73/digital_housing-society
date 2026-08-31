import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/plot_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_assets.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/demo_data.dart';
import '../widgets/responsive_shell.dart';

class PlotMapScreen extends StatefulWidget {
  const PlotMapScreen({super.key});

  @override
  State<PlotMapScreen> createState() => _PlotMapScreenState();
}

class _PlotMapScreenState extends State<PlotMapScreen> {
  final FirestoreService _service = FirestoreService();
  final TransformationController _mapController =
      TransformationController();

  String _phase = 'All';
  String _block = 'All';
  String? _selectedPlotNumber;
  String? _hoveredPlotNumber;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DhsResponsiveShell(
      currentRoute: AppConstants.mapRoute,
      mobileTitle: 'Static Plot Map',
      child: StreamBuilder<QuerySnapshot>(
        stream: _service.getPlots(),
        builder: (context, snapshot) {
          final firestorePlots = (snapshot.data?.docs ?? const [])
              .map(PlotModel.fromFirestore)
              .toList();

          // Live Firestore data is primary. Until the admin module publishes
          // official plots, keep the approved master-plan demo fully usable.
          final plots = firestorePlots.isNotEmpty
              ? firestorePlots
              : DemoData.plotModels;

          final phases = _options(
            plots.map((plot) => plot.phase),
          );
          final blocks = _options(
            plots.map((plot) => plot.block),
          );

          final visiblePlots = plots.where((plot) {
            final phaseOk = _phase == 'All' || plot.phase == _phase;
            final blockOk = _block == 'All' || plot.block == _block;
            return phaseOk && blockOk;
          }).toList();

          final plotByNumber = <String, PlotModel>{
            for (final plot in visiblePlots) plot.plotNumber: plot,
          };

          _ensureSelection(visiblePlots);

          final selected = _selectedPlotNumber == null
              ? null
              : plotByNumber[_selectedPlotNumber!];

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.sizeOf(context).width >= 980 ? 24 : 12,
              vertical: 18,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1320),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _MapHero(
                      phases: phases,
                      blocks: blocks,
                      phase: _phase,
                      block: _block,
                      onPhaseChanged: (value) {
                        setState(() => _phase = value);
                      },
                      onBlockChanged: (value) {
                        setState(() => _block = value);
                      },
                      onFullScreen: () => _showFullScreenMap(
                        plotByNumber,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _MapLegend(),
                    const SizedBox(height: 12),
                    _MapViewport(
                      controller: _mapController,
                      plotByNumber: plotByNumber,
                      selectedPlotNumber: _selectedPlotNumber,
                      hoveredPlotNumber: _hoveredPlotNumber,
                      activeBlock: _block,
                      onPlotTap: (number) {
                        setState(() => _selectedPlotNumber = number);
                      },
                      onPlotHover: (number) {
                        setState(() => _hoveredPlotNumber = number);
                      },
                      onZoomIn: () => _zoom(1.18),
                      onZoomOut: () => _zoom(.84),
                      onReset: _resetZoom,
                    ),
                    const SizedBox(height: 16),
                    if (snapshot.connectionState ==
                        ConnectionState.waiting)
                      const _LoadingCard()
                    else if (plots.isEmpty)
                      const _MapNotice(
                        title: 'No plot records published yet',
                        message:
                            'The master plan is ready. Add plot documents in Firestore to activate live prices, availability and details.',
                      )
                    else if (selected == null)
                      const _MapNotice(
                        title: 'Select a published plot',
                        message:
                            'Tap a highlighted plot on the map to view its live Firestore details.',
                      )
                    else
                      _SelectedPlotCard(plot: selected),
                    const SizedBox(height: 10),
                    const _MapHint(),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _ensureSelection(List<PlotModel> plots) {
    if (plots.isEmpty) {
      _selectedPlotNumber = null;
      return;
    }

    if (_selectedPlotNumber != null &&
        plots.any((plot) => plot.plotNumber == _selectedPlotNumber)) {
      return;
    }

    final preferred = plots.where((plot) => plot.plotNumber == '245');
    _selectedPlotNumber =
        preferred.isNotEmpty ? preferred.first.plotNumber : plots.first.plotNumber;
  }

  List<String> _options(Iterable<String> raw) {
    final values = raw
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...values];
  }

  void _zoom(double factor) {
    final current = _mapController.value;
    _mapController.value = current.clone()..scaleByDouble(factor, factor, 1.0, 1.0);
  }

  void _resetZoom() {
    _mapController.value = Matrix4.identity();
  }

  void _showFullScreenMap(Map<String, PlotModel> plotByNumber) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .6),
      builder: (context) {
        return Dialog.fullscreen(
          backgroundColor: const Color(0xFFF7F8FC),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'DHS Master Plan',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: InteractiveViewer(
                    minScale: .55,
                    maxScale: 3,
                    boundaryMargin: const EdgeInsets.all(120),
                    child: SizedBox(
                      width: 1120,
                      height: 760,
                      child: _MasterPlanCanvas(
                        plotByNumber: plotByNumber,
                        selectedPlotNumber: _selectedPlotNumber,
                        hoveredPlotNumber: _hoveredPlotNumber,
                        activeBlock: _block,
                        onPlotTap: (number) {
                          setState(() => _selectedPlotNumber = number);
                        },
                        onPlotHover: (number) {
                          setState(() => _hoveredPlotNumber = number);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MapHero extends StatelessWidget {
  const _MapHero({
    required this.phases,
    required this.blocks,
    required this.phase,
    required this.block,
    required this.onPhaseChanged,
    required this.onBlockChanged,
    required this.onFullScreen,
  });

  final List<String> phases;
  final List<String> blocks;
  final String phase;
  final String block;
  final ValueChanged<String> onPhaseChanged;
  final ValueChanged<String> onBlockChanged;
  final VoidCallback onFullScreen;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepPurple.withValues(alpha: .18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              compact ? 20 : 30,
              compact ? 26 : 32,
              compact ? 20 : 30,
              compact ? 26 : 34,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1554BF),
                  Color(0xFF2F46D2),
                  Color(0xFF7939E7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              image: DecorationImage(
                image: const AssetImage(AppAssets.courtyardBackground),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  const Color(0xFF4134CF).withValues(alpha: .58),
                  BlendMode.srcATop,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STATIC PLOT MAP',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .84),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Your Plot. Your Future.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 32 : 44,
                    fontWeight: FontWeight.w900,
                    height: 1.04,
                    letterSpacing: -.7,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'Explore the DHS master plan, live plot availability and verified plot details in one place.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .9),
                    fontSize: compact ? 14 : 16,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 640;
                final filterWidth =
                    wide ? 190.0 : constraints.maxWidth;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: filterWidth,
                      child: _MapDropdown(
                        label: 'Phase',
                        value: phases.contains(phase) ? phase : 'All',
                        values: phases,
                        onChanged: onPhaseChanged,
                      ),
                    ),
                    SizedBox(
                      width: filterWidth,
                      child: _MapDropdown(
                        label: 'Block',
                        value: blocks.contains(block) ? block : 'All',
                        values: blocks,
                        onChanged: onBlockChanged,
                      ),
                    ),
                    if (wide)
                      SizedBox(
                        width: 190,
                        child: OutlinedButton.icon(
                          onPressed: onFullScreen,
                          icon: const Icon(Icons.fullscreen_rounded),
                          label: const Text('View Full Screen'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(58),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: constraints.maxWidth,
                        child: OutlinedButton.icon(
                          onPressed: onFullScreen,
                          icon: const Icon(Icons.fullscreen_rounded),
                          label: const Text('View Full Screen'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MapDropdown extends StatelessWidget {
  const _MapDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFF),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE3E6EF)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: values.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item == 'All' ? 'All $label' : item,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const items = [
      ('Available', Color(0xFF64C65A)),
      ('Reserved', Color(0xFFF4B64B)),
      ('Sold', Color(0xFF9AA1AD)),
      ('Selected', Color(0xFF7042EA)),
      ('Park / Amenity', Color(0xFF75B96C)),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E8F0)),
      ),
      child: Wrap(
        spacing: 22,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: items
            .map(
              (item) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: item.$2,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    item.$1,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MapViewport extends StatelessWidget {
  const _MapViewport({
    required this.controller,
    required this.plotByNumber,
    required this.selectedPlotNumber,
    required this.hoveredPlotNumber,
    required this.activeBlock,
    required this.onPlotTap,
    required this.onPlotHover,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  final TransformationController controller;
  final Map<String, PlotModel> plotByNumber;
  final String? selectedPlotNumber;
  final String? hoveredPlotNumber;
  final String activeBlock;
  final ValueChanged<String> onPlotTap;
  final ValueChanged<String?> onPlotHover;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;

    return Container(
      height: compact ? 510 : 660,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF1F4),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFD9DDE5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C6699).withValues(alpha: .08),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: controller,
                minScale: .6,
                maxScale: 2.6,
                boundaryMargin: const EdgeInsets.all(100),
                constrained: false,
                child: SizedBox(
                  width: 1080,
                  height: 720,
                  child: _MasterPlanCanvas(
                    plotByNumber: plotByNumber,
                    selectedPlotNumber: selectedPlotNumber,
                    hoveredPlotNumber: hoveredPlotNumber,
                    activeBlock: activeBlock,
                    onPlotTap: onPlotTap,
                    onPlotHover: onPlotHover,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 14,
              top: 14,
              child: Column(
                children: [
                  _MapControlButton(
                    icon: Icons.add_rounded,
                    onTap: onZoomIn,
                  ),
                  const SizedBox(height: 8),
                  _MapControlButton(
                    icon: Icons.remove_rounded,
                    onTap: onZoomOut,
                  ),
                  const SizedBox(height: 8),
                  _MapControlButton(
                    icon: Icons.center_focus_strong_rounded,
                    onTap: onReset,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MasterPlanCanvas extends StatelessWidget {
  const _MasterPlanCanvas({
    required this.plotByNumber,
    required this.selectedPlotNumber,
    required this.hoveredPlotNumber,
    required this.activeBlock,
    required this.onPlotTap,
    required this.onPlotHover,
  });

  final Map<String, PlotModel> plotByNumber;
  final String? selectedPlotNumber;
  final String? hoveredPlotNumber;
  final String activeBlock;
  final ValueChanged<String> onPlotTap;
  final ValueChanged<String?> onPlotHover;

  static const List<String> _blockA = [
    '101', '102', '103', '104', '105', '106', '107', '108',
    '109', '110', '111', '112', '113', '114', '115', '116',
  ];
  static const List<String> _blockB = [
    '235', '236', '237', '238', '239', '246',
    '240', '241', '242', '243', '244', '245',
    '247', '248', '249', '250', '251', '252',
  ];
  static const List<String> _blockC = [
    '201', '202', '203', '204', '205', '206',
    '207', '208', '209', '210', '211', '212',
    '213', '214', '215', '216', '217', '218',
  ];
  static const List<String> _blockD = [
    '401', '402', '403',
    '404', '405', '406',
    '407', '408', '409',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE7E9E8),
      padding: const EdgeInsets.all(26),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _RoadPainter(),
            ),
          ),
          Positioned(
            left: 40,
            top: 42,
            width: 380,
            child: _BlockPanel(
              label: 'BLOCK A',
              blockCode: 'A',
              numbers: _blockA,
              columns: 8,
              plotByNumber: plotByNumber,
              selectedPlotNumber: selectedPlotNumber,
              hoveredPlotNumber: hoveredPlotNumber,
              dimmed: activeBlock != 'All' && activeBlock != 'A',
              onPlotTap: onPlotTap,
              onPlotHover: onPlotHover,
            ),
          ),
          Positioned(
            left: 40,
            top: 320,
            width: 380,
            child: _BlockPanel(
              label: 'BLOCK B',
              blockCode: 'B',
              numbers: _blockB,
              columns: 6,
              plotByNumber: plotByNumber,
              selectedPlotNumber: selectedPlotNumber,
              hoveredPlotNumber: hoveredPlotNumber,
              dimmed: activeBlock != 'All' && activeBlock != 'B',
              onPlotTap: onPlotTap,
              onPlotHover: onPlotHover,
            ),
          ),
          Positioned(
            left: 470,
            top: 42,
            width: 280,
            child: _BlockPanel(
              label: 'BLOCK D',
              blockCode: 'D',
              numbers: _blockD,
              columns: 3,
              plotByNumber: plotByNumber,
              selectedPlotNumber: selectedPlotNumber,
              hoveredPlotNumber: hoveredPlotNumber,
              dimmed: activeBlock != 'All' && activeBlock != 'D',
              onPlotTap: onPlotTap,
              onPlotHover: onPlotHover,
            ),
          ),
          Positioned(
            left: 470,
            top: 315,
            width: 285,
            height: 155,
            child: _AmenityPanel(
              label: 'CENTRAL PARK',
              icon: Icons.park_rounded,
            ),
          ),
          Positioned(
            left: 40,
            bottom: 35,
            width: 380,
            child: _BlockPanel(
              label: 'BLOCK C',
              blockCode: 'C',
              numbers: _blockC,
              columns: 6,
              plotByNumber: plotByNumber,
              selectedPlotNumber: selectedPlotNumber,
              hoveredPlotNumber: hoveredPlotNumber,
              dimmed: activeBlock != 'All' && activeBlock != 'C',
              onPlotTap: onPlotTap,
              onPlotHover: onPlotHover,
            ),
          ),
          const Positioned(
            right: 35,
            bottom: 35,
            width: 255,
            height: 190,
            child: _AmenityPanel(
              label: 'COMMERCIAL',
              icon: Icons.apartment_rounded,
            ),
          ),
          const Positioned(
            top: 3,
            left: 380,
            child: _RoadLabel(text: '40 ft WIDE ROAD'),
          ),
          const Positioned(
            left: 2,
            top: 245,
            child: RotatedBox(
              quarterTurns: 3,
              child: _RoadLabel(text: '60 ft WIDE ROAD'),
            ),
          ),
          const Positioned(
            right: 2,
            top: 255,
            child: RotatedBox(
              quarterTurns: 1,
              child: _RoadLabel(text: '50 ft WIDE ROAD'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockPanel extends StatelessWidget {
  const _BlockPanel({
    required this.label,
    required this.blockCode,
    required this.numbers,
    required this.columns,
    required this.plotByNumber,
    required this.selectedPlotNumber,
    required this.hoveredPlotNumber,
    required this.dimmed,
    required this.onPlotTap,
    required this.onPlotHover,
  });

  final String label;
  final String blockCode;
  final List<String> numbers;
  final int columns;
  final Map<String, PlotModel> plotByNumber;
  final String? selectedPlotNumber;
  final String? hoveredPlotNumber;
  final bool dimmed;
  final ValueChanged<String> onPlotTap;
  final ValueChanged<String?> onPlotHover;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: dimmed ? .38 : 1,
      duration: const Duration(milliseconds: 180),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 28, 10, 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .72),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFC8CDD5)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -23,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: const Color(0xFFD1D5DD)),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF29324B),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: numbers.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
                childAspectRatio: 1.22,
              ),
              itemBuilder: (context, index) {
                final number = numbers[index];
                final backendPlot = plotByNumber[number];
                return _MapPlotTile(
                  number: number,
                  plot: backendPlot,
                  selected: selectedPlotNumber == number,
                  hovered: hoveredPlotNumber == number,
                  onTap: () {
                    if (backendPlot != null) onPlotTap(number);
                  },
                  onHover: (hovering) {
                    onPlotHover(hovering ? number : null);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPlotTile extends StatelessWidget {
  const _MapPlotTile({
    required this.number,
    required this.plot,
    required this.selected,
    required this.hovered,
    required this.onTap,
    required this.onHover,
  });

  final String number;
  final PlotModel? plot;
  final bool selected;
  final bool hovered;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  @override
  Widget build(BuildContext context) {
    final status = plot?.status.toLowerCase() ?? 'unpublished';
    final background = selected
        ? const Color(0xFFF0E9FF)
        : status.contains('available')
            ? const Color(0xFFBFE8B5)
            : status.contains('reserved')
                ? const Color(0xFFFFD68B)
                : status.contains('sold')
                    ? const Color(0xFFD5D8DE)
                    : Colors.white.withValues(alpha: .82);

    final border = selected
        ? const Color(0xFF7445EB)
        : hovered
            ? const Color(0xFF315DDC)
            : const Color(0xFFC9CDD5);

    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          onTap: plot == null ? null : onTap,
          borderRadius: BorderRadius.circular(7),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: border,
                width: selected ? 2.2 : hovered ? 1.5 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color:
                            AppColors.deepPurple.withValues(alpha: .25),
                        blurRadius: 9,
                      ),
                    ]
                  : const [],
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: selected
                      ? AppColors.deepPurple
                      : const Color(0xFF30384B),
                  fontWeight:
                      selected ? FontWeight.w900 : FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AmenityPanel extends StatelessWidget {
  const _AmenityPanel({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFCFEAC5),
            Color(0xFFA9D49C),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF87B87D)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF4B9146), size: 40),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF315A31),
              fontWeight: FontWeight.w900,
              letterSpacing: .3,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoadLabel extends StatelessWidget {
  const _RoadLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF69707E),
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = const Color(0xFFC8CDD3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 42
      ..strokeCap = StrokeCap.round;

    final lane = Paint()
      ..color = Colors.white.withValues(alpha: .85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final paths = <Path>[
      Path()
        ..moveTo(15, 280)
        ..lineTo(size.width - 25, 280),
      Path()
        ..moveTo(445, 10)
        ..lineTo(445, size.height - 15),
      Path()
        ..moveTo(15, size.height - 145)
        ..lineTo(size.width - 25, size.height - 145),
      Path()
        ..moveTo(size.width - 285, 10)
        ..lineTo(size.width - 285, size.height - 15),
    ];

    for (final path in paths) {
      canvas.drawPath(path, road);
      canvas.drawPath(path, lane);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: AppColors.deepPurple),
      ),
    );
  }
}

class _SelectedPlotCard extends StatelessWidget {
  const _SelectedPlotCard({required this.plot});

  final PlotModel plot;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    final imageAsset = _fallbackAsset(plot.plotNumber);

    final content = [
      _PlotImage(
        plot: plot,
        fallbackAsset: imageAsset,
      ),
      const SizedBox(width: 18, height: 14),
      Expanded(
        flex: compact ? 0 : 5,
        child: _PlotDetails(plot: plot),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4E7EF)),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepPurple.withValues(alpha: .07),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                content[0],
                const SizedBox(height: 14),
                _PlotDetails(plot: plot),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content,
            ),
    );
  }

  static String _fallbackAsset(String number) {
    final value = int.tryParse(number) ?? 0;
    const assets = [
      AppAssets.courtyardBackground,
      AppAssets.heroBackground,
      AppAssets.applyBackground,
      AppAssets.profileBackground,
      AppAssets.authBackground,
    ];
    return assets[value.abs() % assets.length];
  }
}

class _PlotImage extends StatelessWidget {
  const _PlotImage({
    required this.plot,
    required this.fallbackAsset,
  });

  final PlotModel plot;
  final String fallbackAsset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width < 760 ? double.infinity : 250,
      height: MediaQuery.sizeOf(context).width < 760 ? 190 : 220,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          fit: StackFit.expand,
          children: [
            plot.imageUrl.trim().isNotEmpty
                ? Image.network(
                    plot.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      fallbackAsset,
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.asset(
                    fallbackAsset,
                    fit: BoxFit.cover,
                  ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF315DDC),
                      Color(0xFF7C42EC),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  plot.status.isEmpty ? 'Available' : plot.status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlotDetails extends StatelessWidget {
  const _PlotDetails({required this.plot});

  final PlotModel plot;

  @override
  Widget build(BuildContext context) {
    final price = plot.price > 0
        ? NumberFormat.currency(
            locale: 'en_PK',
            symbol: 'PKR ',
            decimalDigits: 0,
          ).format(plot.price)
        : 'Price on request';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plot # ${plot.plotNumber}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.primaryText,
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 12,
          runSpacing: 7,
          children: [
            if (plot.block.isNotEmpty)
              _DetailChip(
                icon: Icons.apartment_rounded,
                label: 'Block ${plot.block}',
              ),
            if (plot.phase.isNotEmpty)
              _DetailChip(
                icon: Icons.flag_outlined,
                label: 'Phase ${plot.phase}',
              ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth =
                constraints.maxWidth >= 620 ? (constraints.maxWidth - 20) / 3 : (constraints.maxWidth - 10) / 2;
            final facts = [
              ('Plot Size', plot.size, Icons.crop_square_rounded),
              ('Category', plot.category, Icons.category_outlined),
              ('Dimensions', plot.dimensions, Icons.straighten_rounded),
              ('Road Width', plot.roadWidth, Icons.add_road_rounded),
              ('Facing', plot.facing, Icons.explore_outlined),
              (
                'Development',
                plot.developmentPercent > 0
                    ? '${plot.developmentPercent}%'
                    : '',
                Icons.stacked_line_chart_rounded,
              ),
            ];

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: facts
                  .map(
                    (fact) => SizedBox(
                      width: itemWidth,
                      child: _FactBox(
                        label: fact.$1,
                        value: fact.$2,
                        icon: fact.$3,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 15),
        Text(
          price,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.deepPurple,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (plot.notes.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            plot.notes,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 15),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 460;
            final back = OutlinedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(
                context,
                AppConstants.plotsRoute,
              ),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Return to Explore'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            );

            final details = DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF315DDC),
                    Color(0xFF7C42EC),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: FilledButton.icon(
                onPressed: () => _showDetails(context),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('View Plot Details'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
              ),
            );

            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  back,
                  const SizedBox(height: 10),
                  details,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: back),
                const SizedBox(width: 10),
                Expanded(child: details),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: .72,
        minChildSize: .52,
        maxChildSize: .92,
        builder: (context, controller) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: ListView(
              controller: controller,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8DCE6),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Plot # ${plot.plotNumber}',
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                _DetailLine(label: 'Block', value: plot.block),
                _DetailLine(label: 'Phase', value: plot.phase),
                _DetailLine(label: 'Plot Size', value: plot.size),
                _DetailLine(label: 'Category', value: plot.category),
                _DetailLine(label: 'Dimensions', value: plot.dimensions),
                _DetailLine(label: 'Road Width', value: plot.roadWidth),
                _DetailLine(label: 'Facing', value: plot.facing),
                _DetailLine(label: 'Location', value: plot.location),
                _DetailLine(label: 'Status', value: plot.status),
                _DetailLine(
                  label: 'Development',
                  value: plot.developmentPercent > 0
                      ? '${plot.developmentPercent}%'
                      : '',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: AppColors.deepPurple),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.deepPurple,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _FactBox extends StatelessWidget {
  const _FactBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: const Color(0xFF687391)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 9.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.trim().isEmpty ? '—' : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.secondaryText,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapNotice extends StatelessWidget {
  const _MapNotice({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF0ECFF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.map_outlined,
              color: AppColors.deepPurple,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryPurple,
        ),
      ),
    );
  }
}

class _MapHint extends StatelessWidget {
  const _MapHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EEFF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.deepPurple,
            size: 19,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Web: hover to preview and click to select. Mobile: pinch to zoom and tap a published plot to view details.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
