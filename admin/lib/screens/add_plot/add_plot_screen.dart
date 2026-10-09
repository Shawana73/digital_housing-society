import 'package:flutter/material.dart';
import '../../widgets/admin_shell.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/premium_widgets.dart';
import 'add_plot_viewmodel.dart';
import 'add_plot_widgets.dart';

class AddPlotScreen extends StatefulWidget {
  const AddPlotScreen({super.key});

  @override
  State<AddPlotScreen> createState() => _AddPlotScreenState();
}

class _AddPlotScreenState extends State<AddPlotScreen> {
  final AddPlotViewModel _viewModel = AddPlotViewModel();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _searchQuery = '';
  static const List<String> _plotSizes = [
    '2 Marla',
    '5 Marla',
    '10 Marla',
    '15 Marla',
    '20 Marla',
  ];

  bool _matchesSearch(String label) {
    if (_searchQuery.isEmpty) return true;
    return label.toLowerCase().contains(_searchQuery);
  }

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.loadSchemes();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required field';
    return null;
  }
  String? _priceValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required field';
    }

    final price = double.tryParse(value.trim());

    if (price == null || price <= 0) {
      return 'Enter a valid price';
    }

    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final schemeError = _viewModel.validateSchemeSize();
    if (schemeError != null) {
      showAdminSnack(context, schemeError);
      return;
    }


    try {
      await _viewModel.savePlot();
      showAdminSnack(context, 'Plot ${_viewModel.plotId.text.trim()} saved successfully!');
      _viewModel.reset();
    } catch (e) {
      showAdminSnack(context, 'Error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Add Plot',
      selectedIndex: 0,
      searchController: _searchController,
      searchHint: 'Search form fields...',
      onSearchChanged: (value) {
        setState(() {
          _searchQuery = value.trim().toLowerCase();
        });
      },

      onSearchClear: () {
        _searchController.clear();
        setState(() {
          _searchQuery = '';
        });
      },
      onFabTap: _save,
      fabLabel: 'Save',
      fabIcon: Icons.save_rounded,
      isLoading: _isLoading,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        children: [
          PremiumCard(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Offstage(
                    offstage: _searchQuery.isNotEmpty &&
                        !_matchesSearch('Plot ID') &&
                        !_matchesSearch('Plot Size') &&
                        !_matchesSearch('Plot Price (PKR)') &&
                        !_matchesSearch('Location') &&
                        !_matchesSearch('Description'),
                    child: const AddPlotSectionTitle(
                      title: 'New Plot Details',
                      subtitle: 'Add premium inventory to society map',
                    ),
                  ),

                  if (_searchQuery.isEmpty ||
                      _matchesSearch('Plot ID') ||
                      _matchesSearch('Plot Size') ||
                      _matchesSearch('Plot Price (PKR)') ||
                      _matchesSearch('Location') ||
                      _matchesSearch('Description'))
                    const SizedBox(height: 18),
                  Offstage(
                    offstage: !_matchesSearch('Plot ID'),
                    child: AddPlotField(
                      controller: _viewModel.plotId,
                      label: 'Plot ID',
                      icon: Icons.badge_rounded,
                      validator: _required,
                    ),
                  ),
                  Offstage(
                    offstage: !_matchesSearch('Plot Size'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(_viewModel.plotSize.text.isEmpty
                            ? 'none'
                            : _viewModel.plotSize.text),
                        initialValue: _viewModel.plotSize.text.isEmpty
                            ? null
                            : _viewModel.plotSize.text,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Plot Size',
                          prefixIcon: Icon(Icons.aspect_ratio_rounded),
                        ),
                        items: _plotSizes
                            .map((size) => DropdownMenuItem<String>(
                          value: size,
                          child: Text(size),
                        ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _viewModel.plotSize.text = value ?? '';
                          });
                        },
                        validator: (v) =>
                        v == null ? 'Please select a plot size' : null,
                      ),
                    ),
                  ),
                  Offstage(
                    offstage: !_matchesSearch('Scheme'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(_viewModel.selectedSchemeId ?? 'none'),
                        initialValue: _viewModel.selectedSchemeId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Scheme',
                          prefixIcon: Icon(Icons.domain_rounded),
                        ),
                        items: _viewModel.schemes
                            .map((s) => DropdownMenuItem<String>(
                          value: s.documentId,
                          child: Text('${s.name} (${s.size})',
                              overflow: TextOverflow.ellipsis),
                        ))
                            .toList(),
                        onChanged: _viewModel.selectScheme,
                        validator: (v) =>
                        v == null ? 'Please select a scheme' : null,
                      ),
                    ),
                  ),
                  Offstage(
                    offstage: !_matchesSearch('Plot Price (PKR)'),
                    child: AddPlotField(
                      controller: _viewModel.price,
                      label: 'Plot Price (PKR)',
                      icon: Icons.payments_rounded,
                      validator: _priceValidator,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  Offstage(
                    offstage: !_matchesSearch('Location'),
                    child: AddPlotField(
                      controller: _viewModel.location,
                      label: 'Location',
                      icon: Icons.location_on_rounded,
                      validator: _required,
                    ),
                  ),
                  Offstage(
                    offstage: !_matchesSearch('Description'),
                    child: AddPlotField(
                      controller: _viewModel.description,
                      label: 'Description',
                      icon: Icons.description_rounded,
                      validator: _required,
                      maxLines: 4,
                    ),
                  ),
                  if (_searchQuery.isNotEmpty &&
                      !_matchesSearch('Plot ID') &&
                      !_matchesSearch('Plot Size') &&
                      !_matchesSearch('Plot Price (PKR)') &&
                      !_matchesSearch('Location') &&
                      !_matchesSearch('Description'))
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text('No matching form fields found'),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(onPressed: () { _viewModel.reset(); showAdminSnack(context, 'Form reset'); }, icon: const Icon(Icons.refresh_rounded), label: const Text('Reset'))),
                    const SizedBox(width: 10),
                    Expanded(child: FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_rounded), label: const Text('Save Plot'))),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}