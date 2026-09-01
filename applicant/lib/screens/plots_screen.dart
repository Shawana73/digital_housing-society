import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../utils/app_constants.dart';
import '../utils/demo_data.dart';
import '../widgets/responsive_shell.dart';

class PlotsScreen extends StatefulWidget {
  const PlotsScreen({super.key, this.initialFavouritesOnly = false});

  final bool initialFavouritesOnly;

  @override
  State<PlotsScreen> createState() => _PlotsScreenState();
}

class _PlotsScreenState extends State<PlotsScreen> {
  final FirestoreService _service = FirestoreService();
  final ScrollController _scrollController = ScrollController();

  String _query = '';
  String _phase = 'All';
  String _block = 'All';
  String _size = 'All';
  String _category = 'All';
  String _availability = 'All';
  bool _latestFirst = true;
  bool _favouritesOnly = false;

  final Set<String> _favourites = <String>{};

  static const List<String> _fallbackImages = <String>[
    'assets/backgrounds/housing_bg_courtyard.png',
    'assets/backgrounds/housing_bg_hero.png',
    'assets/backgrounds/housing_bg_apply.png',
    'assets/backgrounds/housing_bg_profile.png',
    'assets/backgrounds/housing_bg_auth.png',
  ];


  @override
  void initState() {
    super.initState();
    _favouritesOnly = widget.initialFavouritesOnly;
    _loadFavourites();
  }

  Future<void> _loadFavourites() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final ids = await _service.getFavoritePlotIds(uid);
      if (!mounted) return;
      setState(() {
        _favourites
          ..clear()
          ..addAll(ids);
      });
    } catch (_) {
      // Keep the screen usable even if favourites cannot be loaded.
    }
  }

  Future<void> _toggleFavourite(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final wasFavourite = _favourites.contains(id);

    setState(() {
      if (wasFavourite) {
        _favourites.remove(id);
      } else {
        _favourites.add(id);
      }
    });

    if (uid == null) return;

    try {
      await _service.setPlotFavourite(
        uid: uid,
        plotId: id,
        favourite: !wasFavourite,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (wasFavourite) {
          _favourites.add(id);
        } else {
          _favourites.remove(id);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Favourite could not be updated.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final desktop = screenWidth >= 900;

    return DhsResponsiveShell(
      currentRoute: widget.initialFavouritesOnly
          ? AppConstants.favouritesRoute
          : AppConstants.plotsRoute,
      mobileTitle: widget.initialFavouritesOnly ? 'Favourites' : 'Explore Plots',
      backgroundColor: const Color(0xFFF7F8FC),
      child: SafeArea(
        top: false,
        child: StreamBuilder<QuerySnapshot>(
          stream: _service.getPlots(),
          builder: (context, snapshot) {
            final firestorePlots = snapshot.data?.docs.map((doc) {
                  final map = doc.data() as Map<String, dynamic>;
                  return <String, dynamic>{...map, '_id': doc.id};
                }).toList() ??
                <Map<String, dynamic>>[];

            // Official Firestore data always wins. Demo data is shown only
            // until the admin module publishes real plot records.
            final allPlots = firestorePlots.isNotEmpty
                ? firestorePlots
                : DemoData.plotMaps
                    .map((plot) => Map<String, dynamic>.from(plot))
                    .toList();

            final phases = _options(allPlots, 'phase');
            final blocks = _options(allPlots, 'block');
            final sizes = _options(allPlots, 'size');
            final categories = _categoryOptions(allPlots);
            final statuses = _options(allPlots, 'status');

            final filtered = allPlots.where((plot) {
              final id = (plot['_id'] ?? '').toString();

              final plotNumber = _normalize(plot['plotNumber']);
              final block = _normalize(plot['block']);
              final phase = _normalize(plot['phase']);
              final size = _normalize(plot['size']);
              final category =
                  _normalize(plot['category'] ?? plot['plotType']);
              final status = _normalize(plot['status'] ?? 'Available');

              // Search supports natural phrases such as:
              // "block B", "phase 2", "plot 245", "plot #245",
              // "10 marla", "residential" and "available".
              final searchText = <String>[
                plotNumber,
                'plot $plotNumber',
                'plot #$plotNumber',
                'plot number $plotNumber',
                block,
                'block $block',
                phase,
                'phase $phase',
                size,
                category,
                status,
                _normalize(plot['roadWidth']),
                _normalize(plot['facing']),
                _normalize(plot['location']),
                _normalize(plot['type']),
              ].join(' ');

              final queryOk =
                  searchText.contains(_normalize(_query));
              final phaseOk =
                  _phase == 'All' ||
                  phase == _normalize(_phase);
              final blockOk =
                  _block == 'All' ||
                  block == _normalize(_block);
              final sizeOk =
                  _size == 'All' ||
                  size == _normalize(_size);
              final categoryOk =
                  _category == 'All' ||
                  category == _normalize(_category);
              final availabilityOk =
                  _availability == 'All' ||
                  status == _normalize(_availability);
              final favouriteOk =
                  !_favouritesOnly || _favourites.contains(id);

              return queryOk &&
                  phaseOk &&
                  blockOk &&
                  sizeOk &&
                  categoryOk &&
                  availabilityOk &&
                  favouriteOk;
            }).toList();

            filtered.sort((a, b) {
              final aDate = _dateValue(a['createdAt']);
              final bDate = _dateValue(b['createdAt']);
              return _latestFirst
                  ? bDate.compareTo(aDate)
                  : aDate.compareTo(bDate);
            });

            return Column(
              children: [
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: desktop,
                    trackVisibility: false,
                    thickness: desktop ? 10 : 5,
                    radius: const Radius.circular(20),
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const ClampingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: _HeroAndSearch(
                            onSearch: (value) {
                              setState(() => _query = value.trim());
                            },
                            onNotifications: () {
                              Navigator.pushNamed(
                                context,
                                AppConstants.notificationsRoute,
                              );
                            },
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Center(
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 1240),
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(18, 8, 18, 0),
                                child: _FilterPanel(
                                  phase: _phase,
                                  block: _block,
                                  size: _size,
                                  category: _category,
                                  availability: _availability,
                                  phases: phases,
                                  blocks: blocks,
                                  sizes: sizes,
                                  categories: categories,
                                  statuses: statuses,
                                  onPhase: (value) =>
                                      setState(() => _phase = value),
                                  onBlock: (value) =>
                                      setState(() => _block = value),
                                  onSize: (value) =>
                                      setState(() => _size = value),
                                  onCategory: (value) =>
                                      setState(() => _category = value),
                                  onAvailability: (value) =>
                                      setState(() => _availability = value),
                                  onReset: _resetFilters,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Center(
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 1240),
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(22, 22, 22, 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${filtered.length} Plots Found',
                                        style: const TextStyle(
                                          color: Color(0xFF1C2946),
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      'Sort by:',
                                      style: TextStyle(
                                        color: Color(0xFF65708A),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    PopupMenuButton<bool>(
                                      initialValue: _latestFirst,
                                      onSelected: (value) {
                                        setState(() => _latestFirst = value);
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                          value: true,
                                          child: Text('Latest'),
                                        ),
                                        PopupMenuItem(
                                          value: false,
                                          child: Text('Oldest'),
                                        ),
                                      ],
                                      child: Row(
                                        children: [
                                          Text(
                                            _latestFirst
                                                ? 'Latest'
                                                : 'Oldest',
                                            style: const TextStyle(
                                              color: Color(0xFF6745E8),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: Color(0xFF6745E8),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            snapshot.data == null)
                          const SliverToBoxAdapter(
                            child: LinearProgressIndicator(
                              minHeight: 2,
                              color: Color(0xFF6847E8),
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                        if (filtered.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _EmptyPlots(
                              favouritesOnly: _favouritesOnly,
                            ),
                          )
                        else
                          SliverToBoxAdapter(
                            child: Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 1240),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(18, 0, 18, 28),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final twoColumns =
                                          constraints.maxWidth >= 980;
                                      final itemWidth = twoColumns
                                          ? (constraints.maxWidth - 16) / 2
                                          : constraints.maxWidth;

                                      return Wrap(
                                        spacing: 16,
                                        runSpacing: 16,
                                        children:
                                            List.generate(filtered.length,
                                                (index) {
                                          final plot = filtered[index];
                                          final id =
                                              (plot['_id'] ?? '').toString();

                                          return SizedBox(
                                            width: itemWidth,
                                            child: _PlotCard(
                                              data: plot,
                                              fallbackAsset:
                                                  _fallbackImages[index %
                                                      _fallbackImages.length],
                                              favourite:
                                                  _favourites.contains(id),
                                              onFavourite: () => _toggleFavourite(id),
                                              onMap: () {
                                                Navigator.pushNamed(
                                                  context,
                                                  AppConstants.mapRoute,
                                                );
                                              },
                                              onDetails: () {
                                                _showPlotDetails(plot);
                                              },
                                            ),
                                          );
                                        }),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<String> _options(
    List<Map<String, dynamic>> rows,
    String key,
  ) {
    final values = rows
        .map((row) => (row[key] ?? '').toString().trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return <String>['All', ...values];
  }

  List<String> _categoryOptions(
    List<Map<String, dynamic>> rows,
  ) {
    final values = rows
        .map(
          (row) =>
              (row['category'] ?? row['plotType'] ?? '').toString().trim(),
        )
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return <String>['All', ...values];
  }

  String _normalize(dynamic value) {
    return (value ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  DateTime _dateValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  void _resetFilters() {
    setState(() {
      _phase = 'All';
      _block = 'All';
      _size = 'All';
      _category = 'All';
      _availability = 'All';
      _favouritesOnly = false;
    });
  }

  void _showPlotDetails(Map<String, dynamic> plot) {
    final plotNumber =
        (plot['plotNumber'] ?? plot['_id'] ?? '-').toString();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: .72,
          minChildSize: .5,
          maxChildSize: .9,
          builder: (context, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8DCE6),
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Plot # $plotNumber',
                    style: const TextStyle(
                      color: Color(0xFF111A31),
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Official DHS plot information',
                    style: TextStyle(
                      color: Color(0xFF6B7489),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _DetailRow(label: 'Phase', value: plot['phase']),
                  _DetailRow(label: 'Block', value: plot['block']),
                  _DetailRow(label: 'Plot Size', value: plot['size']),
                  _DetailRow(
                    label: 'Category',
                    value: plot['category'] ?? plot['plotType'],
                  ),
                  _DetailRow(label: 'Status', value: plot['status']),
                  _DetailRow(
                    label: 'Road Width',
                    value: plot['roadWidth'],
                  ),
                  _DetailRow(label: 'Facing', value: plot['facing']),
                  _DetailRow(
                    label: 'Development',
                    value: plot['developmentPercent'] ??
                        plot['developmentStatus'],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF245EDD),
                            Color(0xFF823DE9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            AppConstants.mapRoute,
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        icon: const Icon(Icons.location_on_outlined),
                        label: const Text('View on Society Map'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _HeroAndSearch extends StatelessWidget {
  const _HeroAndSearch({
    required this.onSearch,
    required this.onNotifications,
  });

  final ValueChanged<String> onSearch;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 600;

    return SizedBox(
      height: compact ? 328 : 345,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            bottom: 34,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1552B8),
                    Color(0xFF2939C9),
                    Color(0xFF7237DD),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  const Positioned(
                    right: 20,
                    bottom: 18,
                    child: Opacity(
                      opacity: .18,
                      child: _CityMapArtwork(),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 22 : 42,
                      22,
                      compact ? 22 : 42,
                      28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const _DhsWordmark(),
                            const Spacer(),
                            _NotificationButton(
                              onPressed: onNotifications,
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          'Explore Plots',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 34 : 40,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Find your perfect plot in the perfect location.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .9),
                            fontSize: compact ? 16 : 18,
                          ),
                        ),
                        const SizedBox(height: 22),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: compact ? 18 : 42,
            right: compact ? 18 : 42,
            bottom: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Material(
                  color: Colors.white,
                  elevation: 12,
                  shadowColor:
                      const Color(0xFF4D49A4).withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(22),
                  child: TextField(
                    onChanged: onSearch,
                    decoration: InputDecoration(
                      hintText: 'Search by Plot #, Block or Phase...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF8A93A8),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF6D7891),
                        size: 27,
                      ),
                      suffixIcon: const Icon(
                        Icons.tune_rounded,
                        color: Color(0xFF5360A4),
                        size: 23,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 19,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: const BorderSide(
                          color: Color(0xFFE5E8F0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: const BorderSide(
                          color: Color(0xFF6548E6),
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DhsWordmark extends StatelessWidget {
  const _DhsWordmark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                left: 4,
                bottom: 4,
                child: Container(
                  width: 9,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5CD3FF),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 17,
                bottom: 4,
                child: Container(
                  width: 9,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                bottom: 4,
                child: Container(
                  width: 9,
                  height: 31,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8A75FF),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 9),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DHS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 27,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'DIGITAL HOUSING SOCIETY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 7.5,
                fontWeight: FontWeight.w600,
                letterSpacing: .4,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        children: [
          Positioned.fill(
            child: Material(
              color: Colors.white.withValues(alpha: .11),
              borderRadius: BorderRadius.circular(17),
              child: IconButton(
                onPressed: onPressed,
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
          Positioned(
            right: 7,
            top: 6,
            child: Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: Color(0xFFFF585D),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CityMapArtwork extends StatelessWidget {
  const _CityMapArtwork();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      height: 165,
      child: CustomPaint(
        painter: _CityMapPainter(),
      ),
    );
  }
}

class _CityMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final thin = Paint()
      ..color = Colors.white.withValues(alpha: .75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < 5; i++) {
      final left = 15.0 + i * 38;
      final h = 70.0 + (i % 3) * 20;
      final rect = Rect.fromLTWH(
        left,
        size.height - h - 20,
        30,
        h,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        thin,
      );

      for (var y = rect.top + 12; y < rect.bottom - 8; y += 18) {
        canvas.drawLine(
          Offset(rect.left + 7, y),
          Offset(rect.left + 23, y),
          thin,
        );
      }
    }

    final road = Path()
      ..moveTo(0, size.height - 5)
      ..cubicTo(
        size.width * .35,
        size.height - 40,
        size.width * .65,
        size.height - 60,
        size.width,
        size.height - 25,
      );
    canvas.drawPath(road, paint);

    final pinCenter = Offset(size.width - 42, 38);
    canvas.drawCircle(pinCenter, 20, paint);
    canvas.drawCircle(pinCenter, 6, paint);
    canvas.drawLine(
      Offset(pinCenter.dx, pinCenter.dy + 20),
      Offset(pinCenter.dx, pinCenter.dy + 43),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.phase,
    required this.block,
    required this.size,
    required this.category,
    required this.availability,
    required this.phases,
    required this.blocks,
    required this.sizes,
    required this.categories,
    required this.statuses,
    required this.onPhase,
    required this.onBlock,
    required this.onSize,
    required this.onCategory,
    required this.onAvailability,
    required this.onReset,
  });

  final String phase;
  final String block;
  final String size;
  final String category;
  final String availability;

  final List<String> phases;
  final List<String> blocks;
  final List<String> sizes;
  final List<String> categories;
  final List<String> statuses;

  final ValueChanged<String> onPhase;
  final ValueChanged<String> onBlock;
  final ValueChanged<String> onSize;
  final ValueChanged<String> onCategory;
  final ValueChanged<String> onAvailability;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE6EAF2),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5F69B3).withValues(alpha: .07),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final desktop = width >= 920;
          final tablet = width >= 620;

          final itemWidth = desktop
              ? (width - 24) / 3
              : tablet
                  ? (width - 12) / 2
                  : width;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: itemWidth,
                child: _FilterDropdown(
                  icon: Icons.apartment_rounded,
                  label: 'Phase',
                  value: phase,
                  options: phases,
                  onChanged: onPhase,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _FilterDropdown(
                  icon: Icons.business_rounded,
                  label: 'Block',
                  value: block,
                  options: blocks,
                  onChanged: onBlock,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _FilterDropdown(
                  icon: Icons.crop_square_rounded,
                  label: 'Plot Size',
                  value: size,
                  options: sizes,
                  onChanged: onSize,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _FilterDropdown(
                  icon: Icons.category_outlined,
                  label: 'Category',
                  value: category,
                  options: categories,
                  onChanged: onCategory,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _FilterDropdown(
                  icon: Icons.real_estate_agent_outlined,
                  label: 'Availability',
                  value: availability,
                  options: statuses,
                  onChanged: onAvailability,
                ),
              ),
              SizedBox(
                width: itemWidth,
                height: 64,
                child: TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reset Filters'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6745E8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeOptions = options.contains(value)
        ? options
        : <String>['All', ...options];

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE1E6F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF1EDFF),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF6646E7),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: safeOptions.contains(value) ? value : 'All',
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF4C5569),
                ),
                items: safeOptions.toSet().map((option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: Color(0xFF707A92),
                            fontSize: 10.5,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          option,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF25304C),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) onChanged(newValue);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _PlotCard extends StatelessWidget {
  const _PlotCard({
    required this.data,
    required this.fallbackAsset,
    required this.favourite,
    required this.onFavourite,
    required this.onMap,
    required this.onDetails,
  });

  final Map<String, dynamic> data;
  final String fallbackAsset;
  final bool favourite;
  final VoidCallback onFavourite;
  final VoidCallback onMap;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final plotNumber =
        (data['plotNumber'] ?? data['_id'] ?? '-').toString();
    final block = (data['block'] ?? '-').toString();
    final phase = (data['phase'] ?? '-').toString();
    final size = (data['size'] ?? '-').toString();
    final category =
        (data['category'] ?? data['plotType'] ?? 'Residential').toString();
    final roadWidth = (data['roadWidth'] ?? '-').toString();
    final facing = (data['facing'] ?? '-').toString();
    final status = (data['status'] ?? 'Available').toString();
    final imageUrl = (data['imageUrl'] ?? '').toString().trim();

    final development = _developmentValue(
      data['developmentPercent'] ??
          data['developmentStatus'] ??
          data['development'],
    );

    final facts = [
      _PlotFact(
        icon: Icons.crop_square_rounded,
        label: 'Plot Size',
        value: size,
      ),
      _PlotFact(
        icon: Icons.category_outlined,
        label: 'Category',
        value: category,
      ),
      _PlotFact(
        icon: Icons.add_road_rounded,
        label: 'Road Width',
        value: roadWidth,
      ),
      _PlotFact(
        icon: Icons.explore_outlined,
        label: 'Facing',
        value: facing,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;

        return Container(
          padding: EdgeInsets.all(compact ? 12 : 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: const Color(0xFFE4E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5C66A9).withValues(alpha: .09),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: compact
              ? _buildCompact(
                  plotNumber: plotNumber,
                  block: block,
                  phase: phase,
                  status: status,
                  imageUrl: imageUrl,
                  facts: facts,
                  development: development,
                )
              : _buildWide(
                  plotNumber: plotNumber,
                  block: block,
                  phase: phase,
                  status: status,
                  imageUrl: imageUrl,
                  facts: facts,
                  development: development,
                ),
        );
      },
    );
  }

  Widget _buildCompact({
    required String plotNumber,
    required String block,
    required String phase,
    required String status,
    required String imageUrl,
    required List<_PlotFact> facts,
    required double development,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 190,
          child: _plotImage(
            imageUrl: imageUrl,
            status: status,
          ),
        ),
        const SizedBox(height: 13),
        _titleRow(
          plotNumber: plotNumber,
          block: block,
          phase: phase,
        ),
        const SizedBox(height: 12),
        _factsGrid(facts),
        const SizedBox(height: 12),
        _developmentRow(development),
        const SizedBox(height: 14),
        _buttons(),
      ],
    );
  }

  Widget _buildWide({
    required String plotNumber,
    required String block,
    required String phase,
    required String status,
    required String imageUrl,
    required List<_PlotFact> facts,
    required double development,
  }) {
    return Column(
      children: [
        SizedBox(
          height: 225,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 180,
                child: _plotImage(
                  imageUrl: imageUrl,
                  status: status,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _titleRow(
                      plotNumber: plotNumber,
                      block: block,
                      phase: phase,
                    ),
                    const SizedBox(height: 11),
                    const Divider(
                      height: 1,
                      color: Color(0xFFE8EBF2),
                    ),
                    const SizedBox(height: 11),
                    Expanded(
                      child: _factsGrid(facts),
                    ),
                    const SizedBox(height: 8),
                    _developmentRow(development),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        _buttons(),
      ],
    );
  }

  Widget _plotImage({
    required String imageUrl,
    required String status,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
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
        ),
        Positioned(
          top: 10,
          left: 10,
          child: _AvailabilityBadge(status: status),
        ),
      ],
    );
  }

  Widget _titleRow({
    required String plotNumber,
    required String block,
    required String phase,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Plot # $plotNumber',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF111A31),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              onPressed: onFavourite,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                favourite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: favourite
                    ? const Color(0xFF6745E8)
                    : const Color(0xFF61708C),
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 12,
          runSpacing: 7,
          children: [
            _MetaChip(
              icon: Icons.apartment_rounded,
              text: 'Block $block',
              color: const Color(0xFF3157D5),
            ),
            _MetaChip(
              icon: Icons.flag_outlined,
              text: 'Phase $phase',
              color: const Color(0xFF7C47E6),
            ),
          ],
        ),
      ],
    );
  }

  Widget _factsGrid(List<_PlotFact> facts) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 320 ? 2 : 1;
        const gap = 9.0;
        final width =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: 9,
          children: facts
              .map(
                (fact) => SizedBox(
                  width: width,
                  child: _InfoItem(
                    icon: fact.icon,
                    label: fact.label,
                    value: fact.value,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _developmentRow(double development) {
    return Row(
      children: [
        const Icon(
          Icons.stacked_line_chart_rounded,
          size: 17,
          color: Color(0xFF5B6595),
        ),
        const SizedBox(width: 6),
        const Text(
          'Development',
          style: TextStyle(
            color: Color(0xFF69748C),
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: development / 100,
              minHeight: 6,
              backgroundColor: const Color(0xFFE6E9F0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF6847E8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${development.round()}%',
          style: const TextStyle(
            color: Color(0xFF45516C),
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buttons() {
    final mapButton = OutlinedButton.icon(
      onPressed: onMap,
      icon: const Icon(
        Icons.location_on_outlined,
        size: 20,
      ),
      label: const Text('View on Map'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF3653DD),
        side: const BorderSide(
          color: Color(0xFF3653DD),
          width: 1.2,
        ),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );

    final detailsButton = DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2A5BD7),
            Color(0xFF843BEA),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: FilledButton(
        onPressed: onDetails,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                'View Details',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_rounded,
              size: 19,
            ),
          ],
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 330) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              mapButton,
              const SizedBox(height: 9),
              detailsButton,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: mapButton),
            const SizedBox(width: 9),
            Expanded(child: detailsButton),
          ],
        );
      },
    );
  }

  static double _developmentValue(dynamic value) {
    if (value is num) {
      return value.toDouble().clamp(0, 100).toDouble();
    }

    final text = value?.toString() ?? '';
    final match = RegExp(r'(\d{1,3})').firstMatch(text);
    final parsed = double.tryParse(match?.group(1) ?? '');

    if (parsed != null) {
      return parsed.clamp(0, 100).toDouble();
    }

    return 0;
  }
}

class _PlotFact {
  const _PlotFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 17),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final available =
        status.toLowerCase().contains('available');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        gradient: available
            ? const LinearGradient(
                colors: [
                  Color(0xFF4058E5),
                  Color(0xFF8640E9),
                ],
              )
            : null,
        color: available ? null : const Color(0xFF667085),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: available
                  ? const Color(0xFF5DE15E)
                  : const Color(0xFFFBBF24),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7FB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF5A6597),
            size: 16,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF7A8499),
                  fontSize: 9.5,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF26314C),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyPlots extends StatelessWidget {
  const _EmptyPlots({
    required this.favouritesOnly,
  });

  final bool favouritesOnly;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 25, 24, 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(
                color: Color(0xFFF0ECFF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                favouritesOnly
                    ? Icons.favorite_border_rounded
                    : Icons.map_outlined,
                color: const Color(0xFF6745E8),
                size: 35,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              favouritesOnly
                  ? 'No favourite plots yet'
                  : 'No plots found',
              style: const TextStyle(
                color: Color(0xFF19233A),
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              favouritesOnly
                  ? 'Tap the heart icon on any plot to add it to favourites.'
                  : 'No plot records are available in Firestore yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6C768B),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF69748A),
                fontSize: 14,
              ),
            ),
          ),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF26314A),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
