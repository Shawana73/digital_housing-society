import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_text_styles.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/header_actions.dart';
import '../widgets/illustrations.dart';
import '../widgets/status_badge.dart';

class FileUploadScreen extends StatefulWidget {
  const FileUploadScreen({super.key});

  @override
  State<FileUploadScreen> createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends State<FileUploadScreen> {
  final _imagePicker = ImagePicker();
  final _storageService = StorageService();
  final _firestoreService = FirestoreService();
  File? _cnicFront;
  File? _cnicBack;
  File? _receipt;
  final List<File> _documents = [];
  bool _loading = false;
  double _progress = 0;

  static const int _maxSize = 5 * 1024 * 1024;

  int get _uploadedSteps => (_cnicFront != null && _cnicBack != null ? 1 : 0) + (_documents.isNotEmpty ? 1 : 0) + (_receipt != null ? 1 : 0);

  Future<void> _pickImage(String type) async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 82);
    if (picked == null) return;
    final file = File(picked.path);
    if (!await _validSize(file)) return;
    setState(() {
      if (type == 'front') _cnicFront = file;
      if (type == 'back') _cnicBack = file;
      if (type == 'receipt') _receipt = file;
    });
  }

  Future<void> _pickDocuments() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );
    if (result == null) return;
    final selected = <File>[];
    for (final platformFile in result.files) {
      if (platformFile.path == null) continue;
      final file = File(platformFile.path!);
      if (await file.length() > _maxSize) {
        _showSnack('${platformFile.name} exceeds 5MB limit.');
        continue;
      }
      selected.add(file);
    }
    setState(() {
      _documents
        ..clear()
        ..addAll(selected);
    });
  }

  Future<bool> _validSize(File file) async {
    if (await file.length() > _maxSize) {
      _showSnack('Maximum allowed file size is 5MB.');
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return _showSnack('Please login again.');
    if (_cnicFront == null || _cnicBack == null) return _showSnack('CNIC front and back images are required.');
    setState(() {
      _loading = true;
      _progress = .05;
    });
    try {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final total = 2 + _documents.length + (_receipt == null ? 0 : 1);
      var done = 0;
      Future<String> upload(File file, String path) async {
        final url = await _storageService.uploadFile(file, path);
        done++;
        if (mounted) setState(() => _progress = done / total);
        return url;
      }

      final frontUrl = await upload(_cnicFront!, 'uploads/$uid/cnic_front_$stamp.jpg');
      final backUrl = await upload(_cnicBack!, 'uploads/$uid/cnic_back_$stamp.jpg');
      final documentUrls = <String>[];
      for (var i = 0; i < _documents.length; i++) {
        final file = _documents[i];
        final ext = file.path.split('.').last;
        documentUrls.add(await upload(file, 'uploads/$uid/supporting_${stamp}_$i.$ext'));
      }
      final receiptUrl = _receipt == null ? null : await upload(_receipt!, 'uploads/$uid/receipt_$stamp.jpg');
      await _firestoreService.saveUpload({
        'applicantId': uid,
        'cnicFrontUrl': frontUrl,
        'cnicBackUrl': backUrl,
        'documentUrls': documentUrls,
        'receiptUrl': receiptUrl,
        'uploadedAt': FieldValue.serverTimestamp(),
        'verificationStatus': 'pending',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Documents uploaded successfully.')));
      Navigator.pushReplacementNamed(context, AppConstants.paymentRoute);
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Documents'), actions: const [NotificationBell(), SizedBox(width: 8)]),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Row(children: [Text('Progress', style: AppTextStyles.labelBold), const Spacer(), StatusBadge(text: '$_uploadedSteps/3', type: StatusBadgeType.info)]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(value: _uploadedSteps / 3, minHeight: 9, color: AppColors.primaryPurple, backgroundColor: AppColors.lavender.withValues(alpha: .35)),
          ),
          const SizedBox(height: 18),
          IllustrationBox(painter: FolderPainter(), height: 150),
          const SizedBox(height: 10),
          Text('Upload Required Documents', style: AppTextStyles.headingMedium, textAlign: TextAlign.center),
          Text('CNIC, supporting documents and payment receipt.', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          _UploadCard(
            title: 'CNIC Front & Back',
            subtitle: _cnicFront == null || _cnicBack == null ? 'Front and back images required' : 'CNIC images selected',
            status: _cnicFront != null && _cnicBack != null,
            painter: CnicCardPainter(uploaded: _cnicFront != null && _cnicBack != null),
            preview: _cnicFront,
            actions: [
              OutlinedButton.icon(onPressed: () => _pickImage('front'), icon: const Icon(Icons.credit_card_rounded), label: const Text('Front')),
              OutlinedButton.icon(onPressed: () => _pickImage('back'), icon: const Icon(Icons.credit_card_rounded), label: const Text('Back')),
            ],
          ),
          _UploadCard(
            title: 'Supporting Documents',
            subtitle: _documents.isEmpty ? 'PDF or image files, max 5MB each' : '${_documents.length} file(s) selected',
            status: _documents.isNotEmpty,
            painter: FolderPainter(),
            fileNames: _documents.map((e) => e.path.split(Platform.pathSeparator).last).toList(),
            actions: [OutlinedButton.icon(onPressed: _pickDocuments, icon: const Icon(Icons.attach_file_rounded), label: const Text('Choose Files'))],
          ),
          _UploadCard(
            title: 'Payment Receipt',
            subtitle: _receipt == null ? 'You can upload now or later from Payment screen' : _receipt!.path.split(Platform.pathSeparator).last,
            status: _receipt != null,
            painter: ReceiptPainter(),
            preview: _receipt,
            actions: [OutlinedButton.icon(onPressed: () => _pickImage('receipt'), icon: const Icon(Icons.receipt_long_rounded), label: const Text('Receipt'))],
          ),
          if (_loading) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _progress, color: AppColors.primaryPurple, backgroundColor: AppColors.lightPurpleBackground),
            const SizedBox(height: 12),
          ],
          PrimaryGradientButton(text: 'Submit All', onPressed: _cnicFront != null && _cnicBack != null ? _submit : null, isLoading: _loading),
        ],
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({required this.title, required this.subtitle, required this.status, required this.painter, required this.actions, this.preview, this.fileNames});
  final String title;
  final String subtitle;
  final bool status;
  final CustomPainter painter;
  final List<Widget> actions;
  final File? preview;
  final List<String>? fileNames;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderColor), boxShadow: AppColors.premiumShadow(opacity: .25)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTextStyles.headingSmall)),
              StatusBadge(text: status ? 'Uploaded' : 'Not Uploaded', type: status ? StatusBadgeType.success : StatusBadgeType.warning),
            ],
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: preview == null
                ? IllustrationBox(key: ValueKey('placeholder-$title'), painter: painter, height: 120)
                : ClipRRect(key: ValueKey(preview!.path), borderRadius: BorderRadius.circular(18), child: Image.file(preview!, height: 150, width: double.infinity, fit: BoxFit.cover)),
          ),
          if (fileNames?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            ...fileNames!.map((name) => Padding(padding: const EdgeInsets.only(bottom: 5), child: Row(children: [const Icon(Icons.picture_as_pdf_rounded, color: AppColors.deepPurple, size: 18), const SizedBox(width: 8), Expanded(child: Text(name, style: AppTextStyles.captionText))]))),
          ],
          const SizedBox(height: 14),
          Wrap(spacing: 10, runSpacing: 8, children: actions),
        ],
      ),
    );
  }
}
