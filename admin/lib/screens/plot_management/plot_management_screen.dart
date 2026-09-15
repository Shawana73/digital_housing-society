import 'package:flutter/material.dart';

import '../../models/plot_model.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_shell.dart';
import '../../widgets/premium_widgets.dart';
import '../../app_routes.dart';
import 'plot_viewmodel.dart';
import 'plot_widgets.dart';

class PlotManagementScreen extends StatefulWidget {
  const PlotManagementScreen({super.key});

  @override
  State<PlotManagementScreen> createState() => _PlotManagementScreenState();
}

class _PlotManagementScreenState extends State<PlotManagementScreen> {
  final PlotManagementViewModel _viewModel = PlotManagementViewModel();
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'All';

  static const List<String> _filters = [
    'All',
    'Available',
    'Booked',
    'Allocated',
  ];

  @override
  void initState() {
    super.initState();

    _viewModel.addListener(_onViewModelChanged);
    _viewModel.load();
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await _viewModel.load();
  }

  Future<void> _openEditSheet(PlotModel plot) async {
    String selectedStatus = plot.status;

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AdminColors.primary,
                                AdminColors.secondary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Edit Plot',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AdminColors.darkText,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                plot.plotId,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AdminColors.greyText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Plot Status',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AdminColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AdminColors.border,
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AdminColors.greyText,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Available',
                            child: Text('Available'),
                          ),
                          DropdownMenuItem(
                            value: 'Booked',
                            child: Text('Booked'),
                          ),
                          DropdownMenuItem(
                            value: 'Allocated',
                            child: Text('Allocated'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() {
                              selectedStatus = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, selectedStatus);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
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
      },
    );

    if (result == null || result == plot.status) return;

    try {
      await _viewModel.updateStatus(plot, result);

      if (!mounted) return;

      _showSnack(
        'Plot status updated successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showSnack(
        'Failed to update plot status.',
        isError: true,
      );
    }
  }

  Future<void> _deletePlot(PlotModel plot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Delete Plot?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AdminColors.darkText,
            ),
          ),
          content: Text(
            'Are you sure you want to delete plot ${plot.plotId}? '
                'This action cannot be undone.',
            style: const TextStyle(
              color: AdminColors.greyText,
              height: 1.5,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AdminColors.greyText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _viewModel.deletePlot(plot);

      if (!mounted) return;

      _showSnack(
        'Plot deleted successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showSnack(
        'Failed to delete plot.',
        isError: true,
      );
    }
  }

  void _showSnack(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          backgroundColor:
          isError ? Colors.redAccent : AdminColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  List<PlotModel> _filteredPlots() {
    final plots = _viewModel.filteredPlots;

    if (_selectedFilter == 'All') {
      return plots;
    }

    return plots.where((plot) {
      return plot.status.toLowerCase() ==
          _selectedFilter.toLowerCase();
    }).toList();
  }

  Widget _buildHeading() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AdminColors.primary,
                AdminColors.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AdminColors.primary.withValues(alpha: 0.20),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: const Icon(
            Icons.location_city_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 9,
                runSpacing: 6,
                children: [
                  const Text(
                    'Plots Overview',
                    style: TextStyle(
                      fontSize: 25,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.7,
                      color: AdminColors.darkText,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AdminColors.primary.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'PROPERTY',
                      style: TextStyle(
                        fontSize: 8,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w900,
                        color: AdminColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              const Text(
                'Manage plots, availability and property details.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: AdminColors.greyText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _totalPlotsCard() {
    return Container(
      height: 94,
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AdminColors.primary,
            AdminColors.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AdminColors.primary.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.grid_view_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL PLOTS',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_viewModel.plots.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 700;

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeading(),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: _totalPlotsCard(),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _buildHeading(),
            ),
            const SizedBox(width: 22),
            SizedBox(
              width: 235,
              child: _totalPlotsCard(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddPlotButton() {
    return Material(
      color: Colors.transparent,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamed(
            context,
            AdminRoutes.addPlot,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AdminColors.primary,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: AdminColors.primary.withValues(alpha: 0.30),
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(
          Icons.add_rounded,
          size: 20,
        ),
        label: const Text(
          'Add Plot',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plots = _filteredPlots();

    return AdminShell(
      title: 'Plot Management',
      selectedIndex: 2,
      searchController: _searchController,
      onSearchChanged: _viewModel.search,
      onSearchSubmitted: _viewModel.search,
      onRefresh: _refresh,
      body: Stack(
        children: [
          RefreshIndicator(
            color: AdminColors.primary,
            onRefresh: _refresh,
            child: _viewModel.isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: AdminColors.primary,
              ),
            )
                : LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                int crossAxisCount;

                if (width >= 1500) {
                  crossAxisCount = 4;
                } else if (width >= 1050) {
                  crossAxisCount = 3;
                } else if (width >= 700) {
                  crossAxisCount = 2;
                } else {
                  crossAxisCount = 1;
                }

                final horizontalPadding =
                width < 700 ? 12.0 : 20.0;

                return ListView(
                  physics:
                  const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    20,
                    horizontalPadding,
                    110,
                  ),
                  children: [
                    _buildHeader(),

                    const SizedBox(height: 20),

                    FilterTabs(
                      filters: _filters,
                      selected: _selectedFilter,
                      onSelected: (value) {
                        setState(() {
                          _selectedFilter = value;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    if (plots.isEmpty)
                      PremiumCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 45,
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: AdminColors.primary
                                    .withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.location_off_rounded,
                                color: AdminColors.primary,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No plots found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AdminColors.darkText,
                              ),
                            ),
                            const SizedBox(height: 7),
                            const Text(
                              'Try changing the search or filter.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AdminColors.greyText,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics:
                        const NeverScrollableScrollPhysics(),
                        itemCount: plots.length,
                        gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing:
                          width < 700 ? 12 : 18,
                          mainAxisSpacing:
                          width < 700 ? 12 : 18,
                          childAspectRatio:
                          crossAxisCount == 1
                              ? 1.55
                              : 0.82,
                        ),
                        itemBuilder: (context, index) {
                          final plot = plots[index];

                          return PlotCard(
                            plot: plot,
                            index: index,
                            onEdit: () =>
                                _openEditSheet(plot),
                            onDelete: () =>
                                _deletePlot(plot),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ),

          // Floating Add Plot button.
          // AdminShell is NOT modified.
          Positioned(
            right: 24,
            bottom: 24,
            child: _buildAddPlotButton(),
          ),
        ],
      ),
    );
  }
}