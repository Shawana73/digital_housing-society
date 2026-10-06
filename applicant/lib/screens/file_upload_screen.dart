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
import '../widgets/custom_button.dart';
import '../widgets/responsive_shell.dart';
import '../widgets/status_badge.dart';
import '../widgets/batch3_ui.dart';

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

    if (uid == null) {
      if (mounted) {
        setState(() => _checkingExisting = false);
      }
      return;
    }

    try {
      final doc = await _firestoreService.getUpload(uid);

      if (!mounted) return;

      setState(() {
        _existingUpload = doc?.data() as Map<String, dynamic>?;
      });
    } catch (e) {
      debugPrint('Existing upload check failed: $e');
      // Keep screen usable even if an old upload record cannot be loaded.
    } finally {
      if (mounted) {
        setState(() => _checkingExisting = false);
      }
    }
  }

  String _serial(String id) {
    final r = Random.secure().nextInt(900000) + 100000;
    return 'DHS-${id.toUpperCase().replaceAll('_', '-')}-${DateTime
        .now()
        .year}-$r';
  }

  Future<void> _pickForSlot(int index) async {
    final PlatformFile file;
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: false,
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );
      if (!mounted || result == null || result.files.isEmpty) return;
      file = result.files.first;
    } catch (e) {
      debugPrint('Document picker error: $e');
      if (mounted) _showSnack('Could not open files. Please try again.');
      return;
    }
    final ext = (file.extension ?? file.name
        .split('.')
        .last).toLowerCase();
    if (file.size > _maxSize) {
      return _showSnack('${file.name} exceeds 5MB limit.');
    }
    if (!['pdf', 'png', 'jpg', 'jpeg'].contains(ext)) {
      return _showSnack('${file.name} is not allowed. Use PDF/JPG/PNG.');
    }
    final safeName = RegExp(r'^[A-Za-z0-9 _().-]{3,120}$');
    if (!safeName.hasMatch(file.name)) {
      return _showSnack(
          'Please rename the file using only letters, numbers, spaces, dot, dash, underscore or brackets.');
    }
    // withData is requested, but on some Android providers bytes can still
    // be absent. Show an error rather than crashing on a null assertion.
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      return _showSnack('This file could not be read. Please choose it again.');
    }
    final picked = _DocumentRecord(
      name: file.name,
      type: ext,
      size: file.size,
      serial: _serial(_slots[index].id),
      documentId: _slots[index].id,
      documentTitle: _slots[index].title,
      bytes: bytes,
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

      var savedHere = false;
      try {
        await _firestoreService.saveUpload({
        'applicantId': uid,
        'documents': uploadedDocuments,
        'documentCount': uploadedDocuments.length,
        'requiredCompleted': missing.isEmpty,
        'verificationStatus': 'pending',
        'uploadedAt': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 60));
        savedHere = true;
      } catch (e) {
        // The document itself may have been written before an optional
        // notification or network acknowledgement failed.
        final existing = await _firestoreService.getUpload(uid);
        if (existing == null) rethrow;
        debugPrint('Documents already saved; follow-up action failed: $e');
      }
      if (savedHere) {
        try {
        await FirebaseFirestore.instance.collection('activity_logs').add({
          'applicantId': uid,
          'action': 'Documents uploaded',
          'description':
              'Applicant uploaded ${uploadedDocuments.length} required documents.',
          'type': 'document',
          'timestamp': FieldValue.serverTimestamp(),
        });
        } catch (e) {
          debugPrint('Document activity log could not be written: $e');
        }
      }

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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  int get _selectedCount =>
      _slots.where((s) => s.record != null).length;
  @override
  Widget build(BuildContext context) {
    if (_checkingExisting) {
      return DhsResponsiveShell(
        currentRoute: AppConstants.uploadRoute,
        mobileTitle: 'Documents',
        child: const Scaffold(
          body: SafeArea(
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.deepPurple,
              ),
            ),
          ),
        ),
      );
    }

    if (_existingUpload != null) {
      return DhsResponsiveShell(
        currentRoute: AppConstants.uploadRoute,
        mobileTitle: 'Documents',
        backgroundColor: const Color(0xFFF8F6FD),
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F6FD),
          body: SafeArea(child: ListView(
            padding: const EdgeInsets.fromLTRB(15, 18, 15, 30),
            children: [DhsContentWidth(child: _SubmittedDocumentsView(
              data: _existingUpload!))],
          )),
        ),
      );
    }

    return DhsResponsiveShell(
      currentRoute: AppConstants.uploadRoute,
      mobileTitle: 'Documents',
      backgroundColor: const Color(0xFFF8F6FD),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6FD),
        body: SafeArea(child: ListView(
          padding: const EdgeInsets.fromLTRB(15, 18, 15, 30),
          children: [DhsContentWidth(child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DhsPageBanner(
                eyebrow: 'Application • Supporting files',
                title: 'Required documents',
                subtitle: 'Upload the four required files. Your documents '
                    'will be reviewed after submission.',
                icon: Icons.folder_copy_outlined,
                footer: Text('$_selectedCount of ${_slots.length} selected',
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              const SizedBox(height: 16),
              DhsSection(
                title: 'Upload checklist',
                subtitle: 'Select each item separately. Every file is '
                    'checked before uploading.',
                icon: Icons.fact_check_outlined,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        minHeight: 7,
                        value: _selectedCount / _slots.length,
                        backgroundColor: const Color(0xFFECE6F5),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF7855C6)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _InfoCard(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(builder: (context, constraints) {
                final two = constraints.maxWidth >= 760;
                const gap = 14.0;
                final width = two
                    ? (constraints.maxWidth - gap) / 2
                    : constraints.maxWidth;
                return Wrap(spacing: gap, runSpacing: 14,
                  children: _slots.asMap().entries.map((entry) => SizedBox(
                    width: width,
                    child: _DocumentSlotCard(
                      slot: entry.value,
                      onPick: () => _pickForSlot(entry.key),
                      onRemove: () => setState(() {
                        _slots[entry.key] =
                            _slots[entry.key].copyWith(clearRecord: true);
                      }),
                    ),
                  )).toList(),
                );
              }),
              const SizedBox(height: 18),
              DhsSection(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Ready to submit?',
                      style: TextStyle(fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2C2141))),
                    const SizedBox(height: 6),
                    const Text('All four documents must be selected. '
                      'Your existing file-type and 5 MB checks still apply.',
                      style: TextStyle(color: Color(0xFF786D87),
                        height: 1.4, fontSize: 12.5)),
                    const SizedBox(height: 15),
                    PrimaryGradientButton(
                      text: _loading
                          ? 'Uploading Documents...'
                          : 'Submit Documents',
                      icon: Icons.cloud_upload_outlined,
                      isLoading: _loading,
                      onPressed: _loading ? null : _submit,
                    ),
                  ],
                ),
              ),
            ],
          ))],
        )),
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
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DhsPageBanner(
          eyebrow: 'Saved files',
          title: 'Documents submitted',
          subtitle: 'Your uploaded files are saved and are available '
              'for administration review.',
          icon: Icons.folder_open_outlined,
          footer: Wrap(spacing: 9, runSpacing: 8, children: [
            StatusBadge(text: status.toUpperCase(),
              type: badgeTypeFromStatus(status)),
            Text('${docs.length} documents',
              style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w700, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 16),
        DhsSection(
          title: 'Submitted files',
          subtitle: 'Read from your existing upload record.',
          icon: Icons.inventory_2_outlined,
          child: docs.isEmpty
              ? const Text('No document details available.')
              : Column(children: docs.map<Widget>((item) {
                  final map = item is Map ? item : {};
                  final title = map['documentTitle']?.toString() ?? 'Document';
                  final fileName = map['fileName']?.toString() ?? '-';
                  final type = map['fileType']?.toString().toUpperCase() ?? '';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F6FD),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: const Color(0xFFECE6F5)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.insert_drive_file_outlined,
                          color: Color(0xFF7051BB)),
                      const SizedBox(width: 11),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF352849))),
                          const SizedBox(height: 4),
                          Text('$fileName ${type.isEmpty ? '' : '• $type'}',
                            style: const TextStyle(fontSize: 12.5,
                                color: Color(0xFF70677F)),
                            softWrap: true),
                        ],
                      )),
                      const SizedBox(width: 9),
                      const Icon(Icons.check_circle_outline_rounded,
                        color: Color(0xFF378C65), size: 19),
                    ]),
                  );
                }).toList()),
        ),
        const SizedBox(height: 16),
        PrimaryGradientButton(
          text: 'Continue to Payment',
          icon: Icons.payment_outlined,
          onPressed: () => Navigator.pushReplacementNamed(
              context, AppConstants.paymentRoute),
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

  _DocumentSlot copyWith({_DocumentRecord? record, bool clearRecord = false}) {
    return _DocumentSlot(id: id, title: title, subtitle: subtitle, icon: icon, required: required,
      record: clearRecord ? null : (record ?? this.record));
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

class _InfoCard extends StatelessWidget {
  const _InfoCard();
  @override
  Widget build(BuildContext context) => const DhsDetailWrap(
    twoColumnAt: 500,
    children: [
      DhsInfoBox(label: 'File formats', value: 'PDF, JPG, JPEG, PNG',
          icon: Icons.file_present_outlined),
      DhsInfoBox(label: 'Maximum file size', value: '5 MB per document',
          icon: Icons.data_usage_outlined),
    ],
  );
}

class _DocumentSlotCard extends StatelessWidget {
  const _DocumentSlotCard({required this.slot,
      required this.onPick, required this.onRemove});
  final _DocumentSlot slot;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final record = slot.record;
    final selected = record != null;
    final mb = record == null
        ? '' : (record.size / (1024 * 1024)).toStringAsFixed(2);
    return DhsSection(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(spacing: 10, runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFEAF7EF)
                      : const Color(0xFFF0EBFA),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(selected ? Icons.check_circle_outline : slot.icon,
                  color: selected ? const Color(0xFF2A8754)
                      : const Color(0xFF6748AF)),
              ),
              StatusBadge(text: selected ? 'SELECTED' : 'REQUIRED',
                type: selected ? StatusBadgeType.success
                    : StatusBadgeType.warning),
            ],
          ),
          const SizedBox(height: 12),
          Text(slot.title, style: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 16,
              color: Color(0xFF2D2241))),
          const SizedBox(height: 4),
          Text(slot.subtitle, style: const TextStyle(
              color: Color(0xFF756D81), height: 1.4, fontSize: 12.5)),
          if (selected) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: const Color(0xFFF6F4FA),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(record.type == 'pdf' ? Icons.picture_as_pdf_outlined
                    : Icons.image_outlined, color: const Color(0xFF6748AF)),
                const SizedBox(width: 9),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.name,
                      style: const TextStyle(fontWeight: FontWeight.w700,
                          fontSize: 12.5),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                    Text('${record.type.toUpperCase()} • $mb MB',
                      style: const TextStyle(color: Color(0xFF756C82),
                          fontSize: 12)),
                  ],
                )),
                IconButton(
                  tooltip: 'Remove selected document',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded,
                      color: Color(0xFFAC4D67)),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 15),
          OutlinedButton.icon(
            onPressed: onPick,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6242AF),
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Color(0xFFCEBEED))),
            icon: Icon(selected ? Icons.change_circle_outlined
                : Icons.upload_file_outlined),
            label: Text(selected ? 'Change document' : 'Select document'),
          ),
        ],
      ),
    );
  }
}
