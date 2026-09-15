import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../theme/admin_theme.dart';
import '../../widgets/app_snack.dart';

/// FIX (missing feature): lets the admin add a new balloting scheme
/// directly from the app instead of editing Firestore by hand. Fields
/// written here match SchemeModel.fromMap exactly (name, size, date,
/// status, imagePath), so a scheme created here displays correctly
/// everywhere else in the app.
class AddSchemeScreen extends StatefulWidget {
  const AddSchemeScreen({super.key});

  @override
  State<AddSchemeScreen> createState() => _AddSchemeScreenState();
}

class _AddSchemeScreenState extends State<AddSchemeScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _sizeController = TextEditingController();
  final _imagePathController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    _imagePathController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  String? _validateSize(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Plot size is required';

    final matches =
    RegExp(r'\d+(\.\d+)?\s*marla', caseSensitive: false).hasMatch(v);

    if (!matches) {
      return "Must include a number + 'Marla', e.g. '5 Marla' or '10 Marla Villa'";
    }

    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      showAdminSnack(context, 'Please select a balloting date');
      return;
    }

    final time = _selectedTime ?? const TimeOfDay(hour: 10, minute: 0);

    final combinedDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      time.hour,
      time.minute,
    );

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('schemes').add({
        'name': _nameController.text.trim(),
        'size': _sizeController.text.trim(),
        'date': Timestamp.fromDate(combinedDateTime),
        'status': 'To Be Run',
        'imagePath': _imagePathController.text.trim(),
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showAdminSnack(context, 'Failed to add scheme: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _fieldLabel(
      String text, {
        IconData? icon,
      }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 17,
            color: AdminColors.primary,
          ),
          const SizedBox(width: 7),
        ],
        Text(
          text,
          style: const TextStyle(
            color: AdminColors.darkText,
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
      String hint, {
        IconData? prefixIcon,
      }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AdminColors.greyText.withOpacity(0.62),
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(
        prefixIcon,
        color: AdminColors.primary.withOpacity(0.85),
        size: 20,
      ),
      filled: true,
      fillColor: AdminColors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AdminColors.border.withOpacity(0.8),
          width: 1.1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AdminColors.border.withOpacity(0.8),
          width: 1.1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AdminColors.primary,
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AdminColors.rejected,
          width: 1.2,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AdminColors.rejected,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _sectionCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AdminColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AdminColors.border.withOpacity(0.75),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _infoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AdminColors.primary.withOpacity(0.055),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AdminColors.primary.withOpacity(0.13),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AdminColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: AdminColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create a Balloting Scheme',
                  style: TextStyle(
                    color: AdminColors.darkText,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enter the scheme details below. The scheme will '
                      'appear in upcoming balloting after it is created.',
                  style: TextStyle(
                    color: AdminColors.greyText.withOpacity(0.9),
                    fontSize: 11.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateTimeButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final bool selected =
        label != 'Select date' && label != 'Select time';

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected
            ? AdminColors.primary.withOpacity(0.045)
            : AdminColors.background,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        side: BorderSide(
          color: selected
              ? AdminColors.primary.withOpacity(0.30)
              : AdminColors.border,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AdminColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 16,
              color: AdminColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected
                    ? AdminColors.darkText
                    : AdminColors.greyText,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final bool isMobile = screenWidth < 650;

    final dateLabel = _selectedDate == null
        ? 'Select date'
        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';

    final timeLabel = _selectedTime == null
        ? 'Select time'
        : _selectedTime!.format(context);

    return Scaffold(
      backgroundColor: AdminColors.background,

      // ============================================================
      // APP BAR
      // ============================================================

      appBar: AppBar(
        backgroundColor: AdminColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 20,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.20),
                ),
              ),
              child: const Icon(
                Icons.holiday_village_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New Scheme',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Balloting Management',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      // ============================================================
      // BODY
      // ============================================================

      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 850,
              ),
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 28,
                  vertical: isMobile ? 18 : 28,
                ),
                children: [
                  // --------------------------------------------------
                  // INTRO
                  // --------------------------------------------------

                  _infoBanner(),

                  const SizedBox(height: 20),

                  // --------------------------------------------------
                  // BASIC INFORMATION CARD
                  // --------------------------------------------------

                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Scheme Information',
                          style: TextStyle(
                            color: AdminColors.darkText,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'Provide the basic details of the new housing scheme.',
                          style: TextStyle(
                            color: AdminColors.greyText.withOpacity(0.85),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 20),

                        _fieldLabel(
                          'Scheme Name',
                          icon: Icons.apartment_rounded,
                        ),

                        const SizedBox(height: 8),

                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(
                            color: AdminColors.darkText,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          decoration: _inputDecoration(
                            'e.g. Green Valley Villas',
                            prefixIcon: Icons.home_work_outlined,
                          ),
                          validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Scheme name is required'
                              : null,
                        ),

                        const SizedBox(height: 18),

                        _fieldLabel(
                          'Plot Size',
                          icon: Icons.straighten_rounded,
                        ),

                        const SizedBox(height: 8),

                        TextFormField(
                          controller: _sizeController,
                          style: const TextStyle(
                            color: AdminColors.darkText,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          decoration: _inputDecoration(
                            'e.g. 5 Marla Villa',
                            prefixIcon: Icons.square_foot_rounded,
                          ),
                          validator: _validateSize,
                        ),

                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: AdminColors.background,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.lightbulb_outline_rounded,
                                color: AdminColors.primary,
                                size: 15,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  "Must contain a number + 'Marla' "
                                      "(e.g. '5 Marla') — this is how eligible "
                                      "applicants and plots get matched to this scheme.",
                                  style: TextStyle(
                                    color: AdminColors.greyText,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10.5,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // --------------------------------------------------
                  // DATE & TIME CARD
                  // --------------------------------------------------

                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel(
                          'Balloting Schedule',
                          icon: Icons.event_available_rounded,
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'Choose when this scheme will be available for balloting.',
                          style: TextStyle(
                            color: AdminColors.greyText.withOpacity(0.85),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 18),

                        isMobile
                            ? Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: _dateTimeButton(
                                icon: Icons.calendar_month_rounded,
                                label: dateLabel,
                                onPressed: _pickDate,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: _dateTimeButton(
                                icon: Icons.access_time_rounded,
                                label: timeLabel,
                                onPressed: _pickTime,
                              ),
                            ),
                          ],
                        )
                            : Row(
                          children: [
                            Expanded(
                              child: _dateTimeButton(
                                icon: Icons.calendar_month_rounded,
                                label: dateLabel,
                                onPressed: _pickDate,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _dateTimeButton(
                                icon: Icons.access_time_rounded,
                                label: timeLabel,
                                onPressed: _pickTime,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              color: AdminColors.greyText.withOpacity(0.7),
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Balloting cannot be started before this date/time.',
                                style: TextStyle(
                                  color: AdminColors.greyText,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // --------------------------------------------------
                  // IMAGE CARD
                  // --------------------------------------------------

                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel(
                          'Scheme Image',
                          icon: Icons.image_outlined,
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'Optional — add an asset path for the scheme image.',
                          style: TextStyle(
                            color: AdminColors.greyText.withOpacity(0.85),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _imagePathController,
                          style: const TextStyle(
                            color: AdminColors.darkText,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          decoration: _inputDecoration(
                            'assets/images/your_scheme.png',
                            prefixIcon: Icons.image_search_rounded,
                          ),
                        ),

                        const SizedBox(height: 9),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: AdminColors.greyText.withOpacity(0.7),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Leave blank to show a default placeholder icon instead of an image.',
                                style: TextStyle(
                                  color: AdminColors.greyText,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // --------------------------------------------------
                  // ADD BUTTON
                  // --------------------------------------------------

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: _saving
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(
                        Icons.add_circle_outline_rounded,
                        size: 20,
                      ),
                      label: Text(
                        _saving ? 'Adding Scheme...' : 'Add Scheme',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AdminColors.primary,
                        disabledBackgroundColor:
                        AdminColors.primary.withOpacity(0.55),
                        elevation: 5,
                        shadowColor: AdminColors.primary.withOpacity(0.25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // --------------------------------------------------
                  // FOOTER
                  // --------------------------------------------------

                  Center(
                    child: Text(
                      'Digital Housing Society • Balloting Management',
                      style: TextStyle(
                        color: AdminColors.greyText.withOpacity(0.72),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}