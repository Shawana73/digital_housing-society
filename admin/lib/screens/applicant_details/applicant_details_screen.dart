import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/admin_models.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_shell.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/premium_widgets.dart';
import 'applicant_details_viewmodel.dart';
import 'applicant_details_widgets.dart';

class ApplicantDetailsScreen extends StatefulWidget {
  final Applicant applicant;
  const ApplicantDetailsScreen({super.key, required this.applicant});

  @override
  State<ApplicantDetailsScreen> createState() => _ApplicantDetailsScreenState();
}

class _ApplicantDetailsScreenState extends State<ApplicantDetailsScreen> {
  final TextEditingController _noteController = TextEditingController();
  final ApplicantDetailsViewModel _viewModel = ApplicantDetailsViewModel();

  int _tabIndex = 0;
  final List<String> _tabs = const ['Documents', 'Personal Info', 'Payment Info', 'Activity Log'];

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_refresh);
    _viewModel.loadApplicant(widget.applicant);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_refresh);
    _viewModel.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _showDocumentPreview(ApplicantDocument document) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 40,
        ),
        child: PremiumCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                document.title,
                style: const TextStyle(
                  color: AdminColors.darkText,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),

              if (document.fileUrl.isEmpty)
                const SizedBox(
                  height: 220,
                  child: Center(
                    child: Text('Document URL not available.'),
                  ),
                )
              else if (['jpg', 'jpeg', 'png']
                  .contains(document.fileType.toLowerCase()))
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    document.fileUrl,
                    height: 320,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 220,
                      child: Center(
                        child: Text('Unable to load document.'),
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 120,
                  child: Center(
                    child: FilledButton.icon(
                      onPressed: document.fileUrl.isEmpty
                          ? null
                          : () async {
                        final uri = Uri.tryParse(document.fileUrl);
                        if (uri != null) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Open Document'),
                    ),
                  ),
                ),


              const SizedBox(height: 16),

              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close Preview'),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _setStatus(VerificationStatus status) async {
    try {
      await _viewModel.updateStatus(status);
      if (!mounted) return;
      showAdminSnack(context, '${widget.applicant.name} marked ${status.label}');
    } catch (e) {
      if (!mounted) return;
      showAdminSnack(context, 'Failed to update applicant status');
    }
  }

  Future<void> _saveNote() async {
    final text = _noteController.text.trim();

    if (text.isEmpty) {
      showAdminSnack(context, 'Please enter a note');
      return;
    }

    try {
      await _viewModel.saveNote(text);

      if (!mounted) return;

      _noteController.clear();
      FocusScope.of(context).unfocus();

      showAdminSnack(context, 'Note saved successfully');
    } catch (e) {
      if (!mounted) return;

      showAdminSnack(context, 'Failed to save note');
    }
  }
  String _formatNoteDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      return '${date.day.toString().padLeft(2, '0')} '
          '${_monthName(date.month)} '
          '${date.year}, '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }

    return 'Date not available';
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }
  Future<void> _editNote(int index, String currentText) async {
    final controller = TextEditingController(text: currentText);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminColors.radius)),
        title: const Text('Edit Note', style: TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Update note...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != currentText) {
      try {
        await _viewModel.editNote(index, result);
        if (!mounted) return;
        showAdminSnack(context, 'Note updated');
      } catch (e) {
        if (!mounted) return;
        showAdminSnack(context, 'Failed to update note');
      }
    }
  }

  Future<void> _deleteNote(int index) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminColors.radius)),
        title: const Text('Delete Note?', style: TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900)),
        content: const Text('This note will be permanently removed.', style: TextStyle(color: AdminColors.greyText)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AdminColors.rejected),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _viewModel.deleteNote(index);
        if (!mounted) return;
        showAdminSnack(context, 'Note deleted');
      } catch (e) {
        if (!mounted) return;
        showAdminSnack(context, 'Failed to delete note');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final applicant = _viewModel.applicant;

    if (applicant == null) {
      return AdminShell(
        title: 'Applicant Details',
        selectedIndex: 1,
        isLoading: _viewModel.isLoading,
        body: const Center(child: Text('Unable to load applicant details')),
      );
    }

    return AdminShell(
      title: 'Applicant Details',
      selectedIndex: 1,
      onFabTap: null,
      isLoading: _viewModel.isLoading,
      body: ListView(
        physics: const BouncingScrollPhysics(),
  padding: const EdgeInsets.fromLTRB(16, 14, 16, 150),
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AdminColors.radius),
              boxShadow: [BoxShadow(color: AdminColors.primary.withOpacity(0.28), blurRadius: 28, offset: const Offset(0, 12))],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 1.0,
                    child: Image.asset('assets/images/admin_realestate.png', fit: BoxFit.cover),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF3D1FA8).withOpacity(0.22),
                          const Color(0xFF5A2FE0).withOpacity(0.14),
                          const Color(0xFF6A3CEF).withOpacity(0.08),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(children: [
                            Hero(
                              tag: 'applicant-${applicant.id}',
                              child: CircleAvatar(
                                radius: 38,
                                backgroundColor: Colors.white.withOpacity(0.18),
                                child: Text(applicant.avatarLetters,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)),
                              ),
                            ),
                            if (applicant.status == VerificationStatus.verified)
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  height: 20,
                                  width: 20,
                                  decoration: BoxDecoration(
                                    color: AdminColors.success,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 12),
                                ),
                              ),
                          ]),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(
                                    child:Text(applicant.name,
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 24,
                                          letterSpacing: -.4,
                                          shadows: [Shadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 1))],
                                        )),
                                  ),
                                  StatusPill(label: applicant.status.label, color: applicant.status.color),
                                ]),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                  child: Text(applicant.id,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                                ),
                                const SizedBox(height: 10),
                                _HeaderMiniLine(icon: Icons.email_rounded, text: applicant.email),
                                const SizedBox(height: 6),
                                _HeaderMiniLine(icon: Icons.phone_rounded, text: applicant.phone),
                                const SizedBox(height: 6),
                                _HeaderMiniLine(icon: Icons.location_on_rounded, text: applicant.address, maxLines: 2),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: Colors.white.withOpacity(0.18)),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(child: _HeaderMetaTile(label: 'Applied On', value: _viewModel.appliedOn)),
                              const SizedBox(width: 12),
                              Expanded(child: _HeaderMetaTile(label: 'Last Updated', value: _viewModel.profileCreatedOn)),
                            ]),
                            const SizedBox(height: 12),
                            _HeaderMetaTile(label: 'Application Type', value: _viewModel.applicationType),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          DetailsTabStrip(tabs: _tabs, selected: _tabIndex, onSelected: (i) => setState(() => _tabIndex = i)),
          const SizedBox(height: 16),
          _buildTabContent(applicant),
          const SizedBox(height: 18),
          PremiumCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        color: AdminColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.sticky_note_2_rounded, color: AdminColors.primary, size: 16),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Verification Notes',
                      style: TextStyle(
                        color: AdminColors.darkText,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (_viewModel.notes.isEmpty)
                  const Padding(

                    padding: EdgeInsets.only(bottom: 14),
                    child: Text(
                      'No verification notes have been added yet.',
                      style: TextStyle(
                        color: AdminColors.greyText,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),

                for (int i = 0; i < _viewModel.notes.length; i++)
                  Builder(builder: (context) {
                    final note = _viewModel.notes[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AdminColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AdminColors.primary.withOpacity(0.08)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 30,
                            width: 30,
                            decoration: BoxDecoration(
                              color: AdminColors.primary.withOpacity(0.14),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_rounded, color: AdminColors.primary, size: 15),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatNoteDate(note['createdAt']),
                                  style: const TextStyle(
                                    color: AdminColors.greyText,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  note['text']?.toString() ?? '',
                                  style: const TextStyle(
                                    color: AdminColors.darkText,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.more_vert_rounded, size: 18, color: AdminColors.greyText),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editNote(i, note['text']?.toString() ?? '');
                              } else if (value == 'delete') {
                                _deleteNote(i);
                              }
                            },
                            itemBuilder: (ctx) => const [
                              PopupMenuItem(value: 'edit', child: PopupMenuRow(icon: Icons.edit_rounded, text: 'Edit')),
                              PopupMenuItem(value: 'delete', child: PopupMenuRow(icon: Icons.delete_rounded, text: 'Delete')),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AdminColors.background,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          controller: _noteController,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Add a verification note...',
                            prefixIcon: Icon(Icons.edit_note_rounded, color: AdminColors.primary),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: _saveNote,
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Save'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _buildStatusActionArea(applicant),
        ],
      ),
    );
  }
  Future<void> _confirmAndSetStatus(VerificationStatus status) async {
    final actionLabel = status == VerificationStatus.verified
        ? 'Verify'
        : status == VerificationStatus.rejected
        ? 'Reject'
        : 'Reopen';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminColors.radius)),
        title: Text('$actionLabel Applicant?',
            style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900)),
        content: Text(
          status == VerificationStatus.pending
              ? '${widget.applicant.name} will be reopened for review. Previous decision will be cleared.'
              : '${widget.applicant.name} will be marked as ${status.label}.',
          style: const TextStyle(color: AdminColors.greyText),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(actionLabel)),
        ],
      ),
    );

    if (result == true) {
      await _setStatus(status);
    }
  }

  Widget _buildStatusActionArea(Applicant applicant) {
    if (applicant.status == VerificationStatus.pending) {
      return Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _confirmAndSetStatus(VerificationStatus.rejected),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Reject Applicant'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AdminColors.rejected,
              side: BorderSide(color: AdminColors.rejected.withOpacity(0.4)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _confirmAndSetStatus(VerificationStatus.verified),
            icon: const Icon(Icons.check_circle_rounded, size: 18),
            label: const Text('Verify Applicant'),
            style: FilledButton.styleFrom(backgroundColor: AdminColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ),
      ]);
    }

    final isVerified = applicant.status == VerificationStatus.verified;
    final bannerColor = isVerified ? AdminColors.success : AdminColors.rejected;
    final bannerText = isVerified
        ? 'This applicant has been verified'
        : 'This applicant has been rejected';
    final bannerIcon = isVerified ? Icons.check_circle_rounded : Icons.cancel_rounded;

  return Column(
  children: [
  Container(
  width: double.infinity,
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
  color: bannerColor.withOpacity(0.1),
  borderRadius: BorderRadius.circular(AdminColors.radius),
  border: Border.all(color: bannerColor.withOpacity(0.3)),
  ),
  child: Row(children: [
  Icon(bannerIcon, color: bannerColor),
  const SizedBox(width: 10),
  Expanded(
  child: Text(bannerText,
  style: TextStyle(color: bannerColor, fontWeight: FontWeight.w800, fontSize: 13)),
  ),
  ]),
  ),
  if (_tabIndex == 0) ...[
  const SizedBox(height: 10),
  SizedBox(
  width: double.infinity,
  child: OutlinedButton.icon(
  onPressed: () => _confirmAndSetStatus(VerificationStatus.pending),
  icon: const Icon(Icons.replay_rounded, size: 18),
  label: const Text('Reopen for Review'),
  style: OutlinedButton.styleFrom(
  foregroundColor: AdminColors.darkText,
  side: BorderSide(color: AdminColors.darkText.withOpacity(0.2)),
  padding: const EdgeInsets.symmetric(vertical: 14),
  ),
  ),
  ),
  ],
  ],
  );
  }
  Widget _buildTabContent(Applicant applicant) {
    final locked = applicant.status != VerificationStatus.pending;

    switch (_tabIndex) {
      case 0:
        return DocumentsTab(
          documents: _viewModel.documents,
          onPreview: (document) {
            _showDocumentPreview(document);
          },
          onVerify: locked
              ? null
              : (index) async {
            await _viewModel.updateDocumentStatus(index, 'verified');
          },
          onReject: locked
              ? null
              : (index) async {
            await _viewModel.updateDocumentStatus(index, 'rejected');
          },
        );

      case 1:
        return PersonalInfoTab(viewModel: _viewModel);
      case 2:
        return PaymentInfoTab(viewModel: _viewModel);
      case 3:
        return ActivityLogTab(viewModel: _viewModel);
      default:
        return const SizedBox.shrink();
    }
  }
}
class _HeaderMiniLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final int maxLines;
  const _HeaderMiniLine({required this.icon, required this.text, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
                height: 1.3,
                shadows: [Shadow(color: Colors.black45, blurRadius: 5, offset: Offset(0, 1))],
              )),
        ),
      ],
    );
  }
}

class _HeaderMetaTile extends StatelessWidget {
  final String label;
  final String value;
  const _HeaderMetaTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1))],
        )),
        const SizedBox(height: 3),
        Text(value,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              shadows: [Shadow(color: Colors.black45, blurRadius: 5, offset: Offset(0, 1))],
            )),
      ],
    );
  }
}