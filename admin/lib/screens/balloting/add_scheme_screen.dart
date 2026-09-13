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

    // FIX: enforced at entry time, because every eligibility/plot-matching
    // calculation elsewhere in the app (BallotingViewModel,
    // BallotingProcessingViewModel) extracts the numeric Marla size with
    // this exact pattern. A scheme saved without it would silently never
    // match any applicants or plots.
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
        // New schemes always start as "To Be Run" so they land in
        // Upcoming Ballotings (matches SchemeModel's own default too).
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

  Widget _fieldLabel(String text) => Text(
    text,
    style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w800, fontSize: 13.5),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w500, fontSize: 13.5),
    filled: true,
    fillColor: AdminColors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AdminColors.border, width: 1.2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AdminColors.border, width: 1.2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AdminColors.primary, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AdminColors.rejected, width: 1.2),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final dateLabel = _selectedDate == null
        ? 'Select date'
        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';
    final timeLabel = _selectedTime == null ? 'Select time' : _selectedTime!.format(context);

    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        title: const Text('Add New Scheme'),
        backgroundColor: AdminColors.white,
        foregroundColor: AdminColors.darkText,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _fieldLabel('Scheme Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w700, fontSize: 14),
                decoration: _inputDecoration('e.g. Green Valley Villas'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Scheme name is required' : null,
              ),
              const SizedBox(height: 18),
              _fieldLabel('Plot Size'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _sizeController,
                style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w700, fontSize: 14),
                decoration: _inputDecoration('e.g. 5 Marla Villa'),
                validator: _validateSize,
              ),
              const SizedBox(height: 4),
              const Text(
                "Must contain a number + 'Marla' (e.g. '5 Marla') — this is how eligible applicants and plots get matched to this scheme.",
                style: TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 11, height: 1.4),
              ),
              const SizedBox(height: 18),
              _fieldLabel('Balloting Date & Time'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_rounded, size: 16, color: AdminColors.primary),
                      label: Text(dateLabel, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AdminColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time_rounded, size: 16, color: AdminColors.primary),
                      label: Text(timeLabel, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AdminColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Balloting cannot be started before this date/time.',
                style: TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 11),
              ),
              const SizedBox(height: 18),
              _fieldLabel('Image Path (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _imagePathController,
                style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w700, fontSize: 14),
                decoration: _inputDecoration('assets/images/your_scheme.png'),
              ),
              const SizedBox(height: 4),
              const Text(
                'Leave blank to show a default placeholder icon instead of an image.',
                style: TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 11),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Icon(Icons.add_rounded),
                  label: Text(_saving ? 'Adding...' : 'Add Scheme', style: const TextStyle(fontWeight: FontWeight.w900)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AdminColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}