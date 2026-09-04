import 'dart:math';
import 'dart:typed_data';
import '../services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_text_styles.dart';
import '../widgets/custom_button.dart';
import '../widgets/status_badge.dart';

class FileUploadScreen extends StatefulWidget {
  const FileUploadScreen({super.key});

  @override
  State<FileUploadScreen> createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends State<FileUploadScreen> {
  final _firestoreService = FirestoreService();
  final _storageService = StorageService();
  late final List<_DocumentSlot> _slots;
  bool _loading = false;
  bool _checkingExisting = true;
  Map<String, dynamic>? _existingUpload;

  static const int _maxSize = 5 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    _slots = [
      const _DocumentSlot(
        id: 'cnic_front',
        title: 'CNIC Front Side',
        subtitle: 'Clear front-side image or PDF of applicant CNIC',
        icon: Icons.badge_rounded,
        required: true,
      ),
      const _DocumentSlot(
        id: 'cnic_back',
        title: 'CNIC Back Side',
        subtitle: 'Clear back-side image or PDF of applicant CNIC',
        icon: Icons.credit_card_rounded,
        required: true,
      ),
      const _DocumentSlot(
        id: 'application_form',
        title: 'Signed Application Form',
        subtitle: 'Signed form or acknowledgement slip in PDF/JPG/PNG',
        icon: Icons.description_rounded,
        required: true,
      ),
      const _DocumentSlot(
        id: 'applicant_photo',
        title: 'Recent Photograph',
        subtitle: 'Recent passport-size applicant photograph',
        icon: Icons.person_pin_rounded,
        required: true,
      ),
    ];
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('CURRENT LOGGED-IN UID: $uid');

    final existingUpload = await _firestoreService.getUpload(uid!);

    debugPrint('EXISTING UPLOAD: ${existingUpload?.id}');
    debugPrint('EXISTING UPLOAD DATA: ${existingUpload?.data()}');
    if (uid == null) {
      setState(() => _checkingExisting = false);
      return;
    }
    try {
      final doc = await _firestoreService.getUpload(uid);
      if (!mounted) return;
      setState(() {
        _existingUpload = doc?.data() as Map<String, dynamic>?;
      });
    } catch (_) {
      // Keep screen usable even if old record cannot be loaded.
    } finally {
      if (mounted) setState(() => _checkingExisting = false);
    }
  }

  String _serial(String id) {
    final r = Random.secure().nextInt(900000) + 100000;
    return 'DHS-${id.toUpperCase().replaceAll('_', '-')}-${DateTime
        .now()
        .year}-$r';
  }

  Future<void> _pickForSlot(int index) async {
    final result = await FilePicker.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final ext = (file.extension ?? file.name
        .split('.')
        .last).toLowerCase();
    if (file.size > _maxSize)
      return _showSnack('${file.name} exceeds 5MB limit.');
    if (!['pdf', 'png', 'jpg', 'jpeg'].contains(ext)) {
      return _showSnack('${file.name} is not allowed. Use PDF/JPG/PNG.');
    }
    final safeName = RegExp(r'^[A-Za-z0-9 _().-]{3,120}$');
    if (!safeName.hasMatch(file.name)) {
      return _showSnack(
          'Please rename the file using only letters, numbers, spaces, dot, dash, underscore or brackets.');
    }
    final picked = _DocumentRecord(
      name: file.name,
      type: ext,
      size: file.size,
      serial: _serial(_slots[index].id),
      documentId: _slots[index].id,
      documentTitle: _slots[index].title,
      bytes: file.bytes!,
    );
    setState(() => _slots[index] = _slots[index].copyWith(record: picked));
  }

  Future<void> _submit() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return _showSnack('Please login again.');
    }

    final missing = _slots
        .where((s) => s.required && s.record == null)
        .map((s) => s.title)
        .toList();

    if (missing.isNotEmpty) {
      return _showSnack('Please select: ${missing.join(', ')}');
    }

    final selected = _slots
        .where((s) => s.record != null)
        .map((s) => s.record!)
        .toList();

    setState(() => _loading = true);

    try {
      final uploadedDocuments = <Map<String, dynamic>>[];

      for (final document in selected) {
        final fileUrl = await _storageService.uploadFile(
          document.bytes,
          document.name,
        );

        uploadedDocuments.add(
          document.toMap(fileUrl: fileUrl),
        );
      }

      await _firestoreService
          .saveUpload({
        'applicantId': uid,
        'documents': uploadedDocuments,
        'documentCount': uploadedDocuments.length,
        'requiredCompleted': missing.isEmpty,
        'verificationStatus': 'pending',
        'uploadedAt': FieldValue.serverTimestamp(),
      })
          .timeout(const Duration(seconds: 60));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Documents submitted successfully.'),
        ),
      );

      Navigator.pushReplacementNamed(
        context,
        AppConstants.paymentRoute,
      );
    } catch (e) {
      debugPrint('Document upload error: $e');

      if (mounted) {
        _showSnack(
          'Documents could not be submitted. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  int get _selectedCount =>
      _slots.where((s) => s.record != null).length;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroCard(
                count: _selectedCount,
                total: _slots.length,
              ),
              const SizedBox(height: 18),
              _InfoCard(),
              const SizedBox(height: 18),

              ..._slots.asMap().entries.map(
                    (entry) => _DocumentSlotCard(
                  slot: entry.value,
                  onPick: () => _pickForSlot(entry.key),
                  onRemove: () {
                    setState(() {
                      _slots[entry.key] =
                          _slots[entry.key].copyWith(record: null);
                    });
                  },
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: PrimaryGradientButton(
                  text: _loading
                      ? 'Uploading Documents...'
                      : 'Submit Documents',
                  icon: Icons.cloud_upload_rounded,
                  onPressed: _loading ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmittedDocumentsView extends StatelessWidget {
  const _SubmittedDocumentsView({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final docs = data['documents'] is List ? data['documents'] as List : const [];
    final status = data['verificationStatus']?.toString() ?? 'pending';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppColors.premiumShadow(),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.white,
                child: Icon(Icons.verified_rounded, color: AppColors.successGreen, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text('Documents Submitted', style: AppTextStyles.headingMedium.copyWith(color: AppColors.white))),
              StatusBadge(text: status.toUpperCase(), type: badgeTypeFromStatus(status)),
            ]),
            const SizedBox(height: 12),
            Text('Your document records have been received for review.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white.withValues(alpha: .86))),
          ]),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderColor), boxShadow: AppColors.premiumShadow(opacity: .2)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Submitted Documents', style: AppTextStyles.headingSmall),
              const SizedBox(height: 12),
              if (docs.isEmpty)
                Text('No document details available.', style: AppTextStyles.bodyMedium)
              else
                ...docs.map((item) {
                  final map = item is Map ? item : {};
                  final title = map['documentTitle']?.toString() ?? 'Document';
                  final fileName = map['fileName']?.toString() ?? '-';
                  final type = map['fileType']?.toString().toUpperCase() ?? '';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.pageBackground, borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      const Icon(Icons.insert_drive_file_rounded, color: AppColors.deepPurple),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(title, style: AppTextStyles.labelBold),
                        Text('$fileName ${type.isEmpty ? '' : '• $type'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.captionText),
                      ])),
                      const Icon(Icons.check_circle_rounded, color: AppColors.successGreen),
                    ]),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 18),
        PrimaryGradientButton(
          text: 'Continue to Payment',
          icon: Icons.payment_rounded,
          onPressed: () => Navigator.pushReplacementNamed(context, AppConstants.paymentRoute),
        ),
      ],
    );
  }
}

class _DocumentSlot {
  const _DocumentSlot({required this.id, required this.title, required this.subtitle, required this.icon, required this.required, this.record});
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool required;
  final _DocumentRecord? record;

  _DocumentSlot copyWith({_DocumentRecord? record}) {
    return _DocumentSlot(id: id, title: title, subtitle: subtitle, icon: icon, required: required, record: record);
  }
}

class _DocumentRecord {
  const _DocumentRecord({
    required this.name,
    required this.type,
    required this.size,
    required this.serial,
    required this.documentId,
    required this.documentTitle,
    required this.bytes,
  });

  final String name;
  final String type;
  final int size;
  final String serial;
  final String documentId;
  final String documentTitle;
  final Uint8List bytes;

  Map<String, dynamic> toMap({String? fileUrl}) => {
    'documentId': documentId,
    'documentTitle': documentTitle,
    'fileName': name,
    'fileType': type,
    'fileSize': size,
    'serialNumber': serial,
    'status': 'pending',
    if (fileUrl != null) 'fileUrl': fileUrl,
  };
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.count, required this.total});
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.white.withValues(alpha: .95), borderRadius: BorderRadius.circular(28), boxShadow: AppColors.premiumShadow()),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 54, height: 54, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.folder_copy_rounded, color: AppColors.white)),
          const SizedBox(width: 12),
          Expanded(child: Text('Required Documents', style: AppTextStyles.headingMedium)),
          StatusBadge(text: '$count / $total', type: count == 0 ? StatusBadgeType.warning : StatusBadgeType.success),
        ]),
        const SizedBox(height: 12),
        Text('Select each required document separately and submit them once for review.', style: AppTextStyles.bodyMedium),
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      ('Allowed types', 'PDF, JPG, JPEG, PNG'),
      ('Maximum size', '5MB per document'),
      ('Required items', 'CNIC front/back, form, photo'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white.withValues(alpha: .93), borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.borderColor)),
      child: Column(children: items.map((e) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Text(e.$1, style: AppTextStyles.captionText), const Spacer(), Flexible(child: Text(e.$2, textAlign: TextAlign.right, style: AppTextStyles.labelBold))]))).toList()),
    );
  }
}

class _DocumentSlotCard extends StatelessWidget {
  const _DocumentSlotCard({required this.slot, required this.onPick, required this.onRemove});
  final _DocumentSlot slot;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final record = slot.record;
    final selected = record != null;
    final mb = record == null ? '' : (record.size / (1024 * 1024)).toStringAsFixed(2);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: selected ? AppColors.successGreen.withValues(alpha: .28) : AppColors.borderColor), boxShadow: AppColors.premiumShadow(opacity: .18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(backgroundColor: selected ? AppColors.successLightBackground : AppColors.lightPurpleBackground, child: Icon(selected ? Icons.check_rounded : slot.icon, color: selected ? AppColors.successGreen : AppColors.deepPurple)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(slot.title, style: AppTextStyles.labelBold)), if (slot.required) StatusBadge(text: 'REQUIRED', type: StatusBadgeType.warning)]),
            const SizedBox(height: 3),
            Text(slot.subtitle, style: AppTextStyles.captionText),
          ])),
        ]),
        if (selected) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.pageBackground, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Icon(record.type == 'pdf' ? Icons.picture_as_pdf_rounded : Icons.image_rounded, color: AppColors.deepPurple),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(record.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.labelBold),
                Text('${record.type.toUpperCase()} • $mb MB', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.captionText),
              ])),
              IconButton(onPressed: onRemove, icon: const Icon(Icons.close_rounded, color: AppColors.errorRed)),
            ]),
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: onPick, icon: Icon(selected ? Icons.change_circle_rounded : Icons.upload_file_rounded), label: Text(selected ? 'Change Document' : 'Select Document')),
      ]),
    );
  }
}
