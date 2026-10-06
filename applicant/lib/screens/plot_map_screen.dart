
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/plot_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_assets.dart';
import '../widgets/sharp_photo_backdrop.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../widgets/responsive_shell.dart';
import '../widgets/full_photo.dart';

class PlotMapScreen extends StatefulWidget {
  const PlotMapScreen({super.key});

  @override
  State<PlotMapScreen> createState() => _PlotMapScreenState();
}

class _PlotMapScreenState extends State<PlotMapScreen> {
  final FirestoreService _service = FirestoreService();
  final TransformationController _mapController =
  TransformationController();
  final TextEditingController _searchController = TextEditingController();

  String _phase = 'All';
  String _block = 'All';
  String _searchQuery = '';
  String? _selectedPlotNumber;
  String? _hoveredPlotNumber;
  bool _routeArgumentApplied = false;
  bool _mapViewInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeArgumentApplied) return;
    _routeArgumentApplied = true;
    final argument = ModalRoute.of(context)?.settings.arguments;
    if (argument is String && argument.trim().isNotEmpty) {
      _searchQuery = argument.trim();
      _searchController.text = _searchQuery;
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_mapViewInitialized) {
      _mapViewInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _resetZoom();
      });
    }
    return DhsResponsiveShell(
      currentRoute: AppConstants.mapRoute,
      mobileTitle: 'Static Plot Map',
      child: StreamBuilder<QuerySnapshot>(
        stream: _service.getPlots(),
        builder: (context, snapshot) {
          final firestorePlots = (snapshot.data?.docs ?? const [])
              .map(PlotModel.fromFirestore)
              .toList();

// Plot details come only from live Firestore records. The static map can
// still be viewed when there are no published plots, but no dummy plot data is
// injected into applicant-facing details.
          final plots = firestorePlots;

          final phases = _options(
            plots.map((plot) => plot.phase),
          );
          final blocks = _options(
            plots.map((plot) => plot.block),
          );
          final activePhase = phases.contains(_phase) ? _phase : 'All';
          final activeBlock = blocks.contains(_block) ? _block : 'All';
          final hasPhaseData = phases.length > 1;
          final searchHint = hasPhaseData
              ? 'Search by plot number, block, phase, size or location'
              : 'Search by plot number, block, size or location';

          final visiblePlots = plots.where((plot) {
            final phaseOk = activePhase == 'All' || plot.phase == activePhase;
            final blockOk = activeBlock == 'All' || plot.block == activeBlock;
            return phaseOk && blockOk;
          }).toList();

          final normalizedQuery = _searchQuery.trim().toLowerCase();
          final displayedPlots = normalizedQuery.isEmpty
              ? visiblePlots
              : visiblePlots.where((plot) {
            final searchable = <String>[
              plot.plotNumber,
              plot.id,
              plot.block,
              plot.phase,
              plot.location,
              plot.size,
              plot.category,
            ].join(' ').toLowerCase();
            return searchable.contains(normalizedQuery);
          }).toList();

          final plotByNumber = <String, PlotModel>{
            for (final plot in displayedPlots) plot.plotNumber: plot,
          };

          _ensureSelection(displayedPlots);

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
                      phase: activePhase,
                      block: activeBlock,
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
                    _PlotSearchBar(
                      hintText: searchHint,
                      controller: _searchController,
                      query: _searchQuery,
                      resultCount: displayedPlots.length,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          if (value.trim().isNotEmpty) {
                            _phase = 'All';
                            _block = 'All';
                          }
                        });
                      },
                      onClear: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
                    const SizedBox(height: 12),
                    _MapLegend(
                      statuses: displayedPlots.map((plot) => plot.status),
                    ),
                    const SizedBox(height: 12),
                    _MapViewport(
                      controller: _mapController,
                      plotByNumber: plotByNumber,
                      selectedPlotNumber: _selectedPlotNumber,
                      hoveredPlotNumber: _hoveredPlotNumber,
                      activeBlock: activeBlock,
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
                    else if (displayedPlots.isEmpty)
                        const _MapNotice(
                          title: 'No matching plots',
                          message:
                          'No Firestore plot matches the selected filters or search. Clear the search or choose another phase/block.',
                        )
                      else if (selected == null)
                          const _MapNotice(
                            title: 'Select a published plot',
                            message:
                            'Tap a highlighted plot on the map to view its live Firestore details.',
                          )
                        else
                          _SelectedPlotCard(plot: selected),
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

    final available = plots.where(
          (plot) => plot.status.toLowerCase() == 'available',
    );

    _selectedPlotNumber = available.isNotEmpty
        ? available.first.plotNumber
        : plots.first.plotNumber;
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
    _mapController.value =
    current.clone()..scaleByDouble(factor, factor, 1.0, 1.0);
  }

  void _resetZoom() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final contentWidth = screenWidth >= 980
        ? (screenWidth - 252 - 49).clamp(320.0, 1320.0).toDouble()
        : (screenWidth - 24).clamp(280.0, 1080.0).toDouble();
    final scale = (contentWidth / 1080).clamp(.32, 1.0).toDouble();
    _mapController.value = Matrix4.identity()
      ..scaleByDouble(scale, scale, 1.0, 1.0);
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
                    constrained: false,
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
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: Color(0xFF25233A),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: SharpPhotoBackdrop(
                    asset: AppAssets.mapDesktopLandscapeBackground,
                    compact: compact,
                    background: const Color(0xFF242B36),
                    desktopPhotoWidth: .56,
                    desktopFit: BoxFit.cover,
                    mobileFit: BoxFit.cover,
                    desktopAlignment: Alignment.center,
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withValues(alpha: compact ? .72 : .78),
                          Colors.black.withValues(alpha: compact ? .45 : .48),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 20 : 30,
                    compact ? 26 : 58,
                    compact ? 20 : 30,
                    compact ? 26 : 58,
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
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(14),
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
                    if (phases.length > 1)
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

class _PlotSearchBar extends StatelessWidget {
  const _PlotSearchBar({
    required this.hintText,
    required this.controller,
    required this.query,
    required this.resultCount,
    required this.onChanged,
    required this.onClear,
  });

  final String hintText;
  final TextEditingController controller;
  final String query;
  final int resultCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E6EF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.deepPurple),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: hintText,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (query.trim().isNotEmpty)
            IconButton(
              tooltip: 'Clear search',
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1EDFF),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '$resultCount plots',
                style: const TextStyle(
                  color: AppColors.deepPurple,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({required this.statuses});

  final Iterable<String> statuses;

  @override
  Widget build(BuildContext context) {
    final values = statuses
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    if (values.isEmpty) return const SizedBox.shrink();

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
        children: values.map((status) {
          final label = status
              .split(RegExp(r'\s+'))
              .where((part) => part.isNotEmpty)
              .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
              .join(' ');
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: _mapStatusColor(status),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

Color _mapStatusColor(String rawStatus) {
  final status = rawStatus.trim().toLowerCase();
  return switch (status) {
    'available' => const Color(0xFF64C65A),
    'booked' => const Color(0xFFF4B64B),
    'allocated' => const Color(0xFF9AA1AD),
    _ => const Color(0xFFCBD0DA),
  };
}

double _masterPlanPanelHeight(int plotCount) {
  const tileColumns = 4;
  final tileRows = (plotCount / tileColumns).ceil().clamp(1, 1000).toInt();
  return 70 + tileRows * 59.0;
}

double _masterPlanContentHeight(Iterable<PlotModel> plots) {
  final grouped = <String, int>{};
  for (final plot in plots) {
    final block = plot.block.trim().isEmpty ? 'Unassigned' : plot.block.trim();
    grouped.update(block, (value) => value + 1, ifAbsent: () => 1);
  }

  if (grouped.isEmpty) return 240.0;

  final counts = grouped.values.toList();
  const columns = 3;
  const gap = 16.0;
  const verticalPadding = 48.0;
  var height = verticalPadding;

  for (var index = 0; index < counts.length; index += columns) {
    final end = (index + columns).clamp(0, counts.length).toInt();
    final row = counts.sublist(index, end);
    var tallest = 0.0;
    for (final count in row) {
      final panel = _masterPlanPanelHeight(count);
      if (panel > tallest) tallest = panel;
    }
    height += tallest + gap;
  }

  return height.clamp(240.0, 4200.0).toDouble();
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
    final canvasHeight = _masterPlanContentHeight(plotByNumber.values);
    final viewportHeight = compact
        ? canvasHeight.clamp(300.0, 430.0).toDouble()
        : canvasHeight.clamp(320.0, 500.0).toDouble();

    return Container(
      height: viewportHeight,
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
                minScale: compact ? .32 : .6,
                maxScale: 2.6,
                boundaryMargin: const EdgeInsets.all(100),
                constrained: false,
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

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<PlotModel>>{};
    final plots = plotByNumber.values.toList()
      ..sort((a, b) {
        final blockCompare = a.block.compareTo(b.block);
        if (blockCompare != 0) return blockCompare;
        return _naturalPlotCompare(a.plotNumber, b.plotNumber);
      });

    for (final plot in plots) {
      final key = plot.block.trim().isEmpty ? 'Unassigned' : plot.block.trim();
      grouped.putIfAbsent(key, () => <PlotModel>[]).add(plot);
    }

    final entries = grouped.entries.toList();
    const canvasWidth = 1080.0;
    const columns = 3;
    const gap = 16.0;
    const horizontalPadding = 24.0;
    const panelWidth =
        (canvasWidth - horizontalPadding * 2 - gap * (columns - 1)) / columns;

    final rows = <List<MapEntry<String, List<PlotModel>>>>[];
    for (var index = 0; index < entries.length; index += columns) {
      rows.add(entries.sublist(
        index,
        (index + columns).clamp(0, entries.length).toInt(),
      ));
    }

    double panelHeight(List<PlotModel> values) =>
        _masterPlanPanelHeight(values.length);

    final contentHeight = _masterPlanContentHeight(plots);

    return SizedBox(
      width: canvasWidth,
      height: contentHeight,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFFF0F2F6),
        ),
        child: CustomPaint(
          painter: const _MapGridPainter(),
          child: Padding(
            padding: const EdgeInsets.all(horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (entries.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'No plots match the current filters.',
                        style: TextStyle(color: AppColors.secondaryText),
                      ),
                    ),
                  )
                else
                  ...rows.map((row) {
                    final height = row
                        .map((entry) => panelHeight(entry.value))
                        .fold<double>(0, (maxHeight, value) =>
                    value > maxHeight ? value : maxHeight);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: gap),
                      child: SizedBox(
                        height: height,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var index = 0; index < columns; index++) ...[
                              if (index < row.length)
                                SizedBox(
                                  width: panelWidth,
                                  child: _LiveBlockPanel(
                                    block: row[index].key,
                                    plots: row[index].value,
                                    selectedPlotNumber: selectedPlotNumber,
                                    hoveredPlotNumber: hoveredPlotNumber,
                                    dimmed: activeBlock != 'All' &&
                                        row[index].key != activeBlock,
                                    onPlotTap: onPlotTap,
                                    onPlotHover: onPlotHover,
                                  ),
                                )
                              else
                                const SizedBox(width: panelWidth),
                              if (index != columns - 1) const SizedBox(width: gap),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static int _naturalPlotCompare(String a, String b) {
    final pattern = RegExp(r'^(.*?)(\d+)$');
    final left = pattern.firstMatch(a.trim());
    final right = pattern.firstMatch(b.trim());
    if (left != null && right != null && left.group(1) == right.group(1)) {
      final leftNumber = int.tryParse(left.group(2) ?? '') ?? 0;
      final rightNumber = int.tryParse(right.group(2) ?? '') ?? 0;
      return leftNumber.compareTo(rightNumber);
    }
    return a.compareTo(b);
  }
}

class _LiveBlockPanel extends StatelessWidget {
  const _LiveBlockPanel({
    required this.block,
    required this.plots,
    required this.selectedPlotNumber,
    required this.hoveredPlotNumber,
    required this.dimmed,
    required this.onPlotTap,
    required this.onPlotHover,
  });

  final String block;
  final List<PlotModel> plots;
  final String? selectedPlotNumber;
  final String? hoveredPlotNumber;
  final bool dimmed;
  final ValueChanged<String> onPlotTap;
  final ValueChanged<String?> onPlotHover;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: dimmed ? .36 : 1,
      duration: const Duration(milliseconds: 160),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .96),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFC9CEDA)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF465174).withValues(alpha: .06),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    block == 'Unassigned' ? 'UNASSIGNED BLOCK' : 'BLOCK $block',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF29324B),
                      fontWeight: FontWeight.w900,
                      fontSize: 11.5,
                      letterSpacing: .35,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1EDFF),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${plots.length}',
                    style: const TextStyle(
                      color: AppColors.deepPurple,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: plots.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 1.35,
                ),
                itemBuilder: (context, index) {
                  final plot = plots[index];
                  return _MapPlotTile(
                    plot: plot,
                    selected: selectedPlotNumber == plot.plotNumber,
                    hovered: hoveredPlotNumber == plot.plotNumber,
                    onTap: () => onPlotTap(plot.plotNumber),
                    onHover: (hovering) =>
                        onPlotHover(hovering ? plot.plotNumber : null),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPlotTile extends StatelessWidget {
  const _MapPlotTile({
    required this.plot,
    required this.selected,
    required this.hovered,
    required this.onTap,
    required this.onHover,
  });

  final PlotModel plot;
  final bool selected;
  final bool hovered;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  @override
  Widget build(BuildContext context) {
    final status = plot.status.toLowerCase().trim();
    final background = selected
        ? const Color(0xFFE8DDFF)
        : _mapStatusColor(status).withValues(alpha: .52);
    final border = selected
        ? const Color(0xFF7445EB)
        : hovered
        ? const Color(0xFF315DDC)
        : const Color(0xFFC9CDD5);

    return Tooltip(
      message: [
        plot.plotNumber,
        if (plot.status.trim().isNotEmpty) plot.status,
        if (plot.size.trim().isNotEmpty) plot.size,
      ].join(' • '),
      child: MouseRegion(
        onEnter: (_) => onHover(true),
        onExit: (_) => onHover(false),
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(7),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(7),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 130),
              padding: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: border,
                  width: selected ? 2.2 : hovered ? 1.5 : 1,
                ),
                boxShadow: selected
                    ? [
                  BoxShadow(
                    color: AppColors.deepPurple.withValues(alpha: .22),
                    blurRadius: 8,
                  ),
                ]
                    : const [],
              ),
              child: Center(
                child: Text(
                  plot.plotNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected
                        ? AppColors.deepPurple
                        : const Color(0xFF30384B),
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    fontSize: 9.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  const _MapGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDDE1E8)
      ..strokeWidth = .7;
    const spacing = 36.0;
    for (var x = 0.0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
    final value = number.codeUnits.fold<int>(0, (total, unit) => total + unit);
    const assets = AppAssets.mapGalleryFallbacks;
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
      width: MediaQuery.sizeOf(context).width < 760 ? double.infinity : 210,
      height: MediaQuery.sizeOf(context).width < 760 ? 158 : 168,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FullPhoto(
              asset: fallbackAsset,
              networkUrl: plot.imageUrl.trim(),
            ),
            if (plot.status.trim().isNotEmpty)
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
                    plot.status,
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
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plot # ${plot.plotNumber}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.primaryText,
            fontSize: 22,
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
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth =
            constraints.maxWidth >= 620 ? (constraints.maxWidth - 20) / 3 : (constraints.maxWidth - 10) / 2;
            final facts = <(String, String, IconData)>[
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
            ].where((fact) => fact.$2.trim().isNotEmpty).toList();

            if (facts.isEmpty) return const SizedBox.shrink();

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
        const SizedBox(height: 11),
        if (price.isNotEmpty)
          Text(
            price,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.deepPurple,
              fontSize: 21,
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
        const SizedBox(height: 11),
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
                minimumSize: const Size.fromHeight(44),
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
                  minimumSize: const Size.fromHeight(44),
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
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
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
