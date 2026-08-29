import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';
import '../viewmodels/admin_view_models.dart';
import '../widgets/admin_shell.dart';
import '../widgets/app_snack.dart';
import '../widgets/premium_widgets.dart';

class AddPlotScreen extends StatefulWidget { //This widget represents configuration/identity
  const AddPlotScreen({super.key});

  @override
  State<AddPlotScreen> createState()  => _AddPlotScreenState(); //createState() tells the corresponding state object of that widget.
}

class _AddPlotScreenState extends State<AddPlotScreen> {  //state class ,state management of mutable state of widget AddPlotScreen
  final AddPlotViewModel _viewModel = AddPlotViewModel();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true; //show loading spinner

  @override
  void initState() {  //Jab _AddPlotScreenState pehli baar create/mount hoti hai, tab initial setup start karna.
    super.initState();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _isLoading = false); //check state is alive or not
    });
  }
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _viewModel.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required field';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      showAdminSnack(context, 'Please fill all required fields');
      return;

    }


    try {
      await _viewModel.savePlot();

      showAdminSnack(
        context,
        'Plot ${_viewModel.plotId.text.trim()} saved successfully!',
      );

      _viewModel.reset();
    } catch (e) {
      showAdminSnack(
        context,
        'Error: ${e.toString()}',
      );
    }
  }

  @override   //BuildContext basically widget tree mein kisi widget ki location/reference hota hai.
  Widget build(BuildContext context) {  //build() ka primary kaam screen ki UI widget tree ke structure ko describe/create karna hai
    return AdminShell(
      title: 'Add Plot',
      selectedIndex: 0,
      searchController: _searchController,
      searchHint: 'Search form fields...',
      onSearchClear: _searchController.clear,
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
                  const SectionTitleLocal(title: 'New Plot Details', subtitle: 'Add premium inventory to society map'),
                  const SizedBox(height: 18),
                  _Field(controller: _viewModel.plotId, label: 'Plot ID', icon: Icons.badge_rounded, validator: _required),
                  _Field(controller: _viewModel.plotSize, label: 'Plot Size', icon: Icons.aspect_ratio_rounded, validator: _required),
                  _Field(controller: _viewModel.price, label: 'Plot Price (PKR)', icon: Icons.payments_rounded, validator: _required, keyboardType: TextInputType.number),
                  _Field(controller: _viewModel.location, label: 'Location', icon: Icons.location_on_rounded, validator: _required),
                  _Field(controller: _viewModel.description, label: 'Description', icon: Icons.description_rounded, validator: _required, maxLines: 4),
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

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputType? keyboardType;

  const _Field({required this.controller, required this.label, required this.icon, this.validator, this.maxLines = 1, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: AdminColors.primary)),
      ),
    );
  }
}

class SectionTitleLocal extends StatelessWidget {
  final String title;
  final String subtitle;
  const SectionTitleLocal({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 20)),
      const SizedBox(height: 4),
      Text(subtitle, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w700)),
    ]);
  }
}
