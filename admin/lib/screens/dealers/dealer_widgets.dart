import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/premium_widgets.dart';

class DealerCard extends StatelessWidget {
  final Dealer dealer;
  final bool isReviewing;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onOpenReview;
  final VoidCallback onView;

  const DealerCard({
    super.key,
    required this.dealer,
    required this.isReviewing,
    required this.onApprove,
    required this.onReject,
    required this.onOpenReview,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = dealer.status == VerificationStatus.pending;
    final isVerified = dealer.status == VerificationStatus.verified;
    final isRejected = dealer.status == VerificationStatus.rejected;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientIconBox(icon: Icons.real_estate_agent_rounded, color: dealer.status.color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dealer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 5),
                    Text(dealer.agency,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w700, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              StatusPill(label: dealer.status.label, color: dealer.status.color),
            ],
          ),

          const SizedBox(height: 16),

          // DEALER DETAILS
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AdminColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AdminColors.border),
            ),
            child: Column(children: [
              InfoRow(icon: Icons.credit_card_rounded, label: 'CNIC', value: dealer.cnic),
              InfoRow(icon: Icons.phone_rounded, label: 'Phone', value: dealer.phone),
              InfoRow(icon: Icons.location_city_rounded, label: 'City', value: dealer.city),
            ]),
          ),

          const SizedBox(height: 12),

          // DOCUMENTS PREVIEW — same pattern as the payment receipt preview
          DocumentPreviewBox(
            title: 'Documents',
            subtitle: '${dealer.documents.length} uploaded',
            icon: Icons.folder_rounded,
            verified: isVerified,
            onTap: () => showDealerDocumentsList(context, dealer),
          ),

          const SizedBox(height: 14),

          // PENDING
          if (isPending) _buildPendingActions(),

          // VERIFIED
          if (isVerified) _buildReviewedStatus(),

          // REJECTED
          if (isRejected) _buildRejectedStatus(),

          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(onPressed: onView, icon: const Icon(Icons.visibility_rounded), label: const Text('View Profile')),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.close_rounded, size: 19),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AdminColors.rejected,
              side: BorderSide(color: AdminColors.rejected.withOpacity(0.45)),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: onApprove,
            icon: const Icon(Icons.check_rounded, size: 19),
            label: const Text('Approve'),
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.success,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewedStatus() {
    if (isReviewing) {
      return _buildReviewActions(message: 'Review mode is open. You can update this dealer.');
    }

    return Column(
      children: [
        _statusMessage(icon: Icons.check_circle_rounded, color: AdminColors.success, text: 'This dealer has been verified'),
        const SizedBox(height: 10),
        _openReviewButton(),
      ],
    );
  }

  Widget _buildRejectedStatus() {
    if (isReviewing) {
      return _buildReviewActions(message: 'Review mode is open. You can update this dealer.');
    }

    return Column(
      children: [
        _statusMessage(icon: Icons.cancel_rounded, color: AdminColors.rejected, text: 'This dealer has been rejected'),
        const SizedBox(height: 10),
        _openReviewButton(),
      ],
    );
  }

  Widget _statusMessage({required IconData icon, required Color color, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: color.withOpacity(0.13), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _openReviewButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onOpenReview,
        icon: const Icon(Icons.rate_review_rounded, size: 19),
        label: const Text('Open for Review'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AdminColors.primary,
          side: BorderSide(color: AdminColors.primary.withOpacity(0.35)),
          backgroundColor: AdminColors.primary.withOpacity(0.04),
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildReviewActions({required String message}) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: AdminColors.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.visibility_rounded, color: AdminColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(message, style: const TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.close_rounded, size: 19),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminColors.rejected,
                  side: BorderSide(color: AdminColors.rejected.withOpacity(0.45)),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: onApprove,
                icon: const Icon(Icons.verified_rounded, size: 19),
                label: const Text('Approve'),
                style: FilledButton.styleFrom(
                  backgroundColor: AdminColors.success,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Shows the dealer's uploaded documents in a list (card-level preview,
/// same idea as the payment receipt preview on the Payments screen).
/// Tapping a document opens the actual image preview with a close option.
void showDealerDocumentsList(BuildContext context, Dealer dealer) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(dialogContext).size.height * 0.75),
          child: PremiumCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AdminColors.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.folder_rounded, color: AdminColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Dealer Documents',
                        style: TextStyle(color: AdminColors.darkText, fontSize: 18, fontWeight: FontWeight.w900)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close_rounded),
                    color: AdminColors.greyText,
                  ),
                ]),
                const SizedBox(height: 14),
                Flexible(
                  child: SingleChildScrollView(
                    child: dealer.documents.isEmpty
                        ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text('No documents uploaded',
                            style: TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w700)),
                      ),
                    )
                        : Column(
                      children: dealer.documents.map((raw) {
                        final doc = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
                        final url = (doc['url'] ??
                            doc['fileUrl'] ??
                            doc['downloadUrl'] ??
                            doc['secureUrl'] ??
                            doc['secure_url'] ??
                            doc['imageUrl'] ??
                            '')
                            .toString();
                        final name =
                        (doc['name'] ?? doc['fileName'] ?? doc['title'] ?? doc['documentTitle'] ?? 'Document')
                            .toString();
                        final type = (doc['type'] ?? doc['fileType'] ?? '').toString().toLowerCase();

                        return InkWell(
                          onTap: url.isEmpty
                              ? null
                              : () => showDocumentImagePreview(context, name: name, url: url, type: type),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AdminColors.background,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AdminColors.border),
                            ),
                            child: Row(children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                    color: AdminColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.insert_drive_file_rounded, color: AdminColors.primary),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800, color: AdminColors.darkText, fontSize: 13)),
                              ),
                              if (url.isNotEmpty)
                                const Icon(Icons.visibility_rounded, color: AdminColors.primary)
                              else
                                const Text('No URL found',
                                    style: TextStyle(
                                        color: AdminColors.rejected, fontSize: 11, fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Full image/PDF preview for a single document, with a Close Preview option.
/// Shared by the card-level documents list and the 5-step profile dialog.
void showDocumentImagePreview(BuildContext context, {required String name, required String url, required String type}) {
  final isPdf = type == 'pdf' || url.toLowerCase().endsWith('.pdf');

  showDialog(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: PremiumCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AdminColors.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.image_rounded, color: AdminColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close_rounded),
                  color: AdminColors.greyText,
                ),
              ]),
              const SizedBox(height: 14),
              Container(
                height: 420,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AdminColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AdminColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: isPdf
                    ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.picture_as_pdf_rounded, size: 64, color: AdminColors.greyText),
                      SizedBox(height: 10),
                      Text('PDF preview not supported here',
                          style: TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w700)),
                    ],
                  ),
                )
                    : Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: AdminColors.primary),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image_rounded, size: 64, color: AdminColors.greyText),
                          SizedBox(height: 10),
                          Text('Unable to load document',
                              style: TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Close Preview'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ================= SUMMARY BANNER =================
class DealerStatsBanner extends StatelessWidget {
  final List<Dealer> dealers;
  const DealerStatsBanner({super.key, required this.dealers});

  @override
  Widget build(BuildContext context) {
    final total = dealers.length;
    final pending = dealers.where((d) => d.status == VerificationStatus.pending).length;
    final verified = dealers.where((d) => d.status == VerificationStatus.verified).length;
    final rejected = dealers.where((d) => d.status == VerificationStatus.rejected).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 230 + 74,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Container(
                  height: 230,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/Sunshine Residency.png'),
                      fit: BoxFit.cover,
                      alignment: Alignment.topRight,
                    ),
                    boxShadow: [
                      BoxShadow(color: AdminColors.primary.withOpacity(0.28), blurRadius: 30, offset: const Offset(0, 14)),
                    ],
                  ),
                  child: Stack(children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              const Color(0xFF5A2FE0).withOpacity(0.55),
                              const Color(0xFF6A3CEF).withOpacity(0.30),
                              const Color(0xFF6A3CEF).withOpacity(0.10),
                            ],
                            stops: const [0.0, 0.55, 1.0],
                          ),
                        ),
                      ),
                    ),
                    const Positioned(right: -34, top: -34, child: DealerGlow(110, opacity: 0.08)),
                    const Positioned(left: -46, bottom: -46, child: DealerGlow(120, opacity: 0.05)),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 22, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dealer Verification',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -.5)),
                          SizedBox(height: 4),
                          Text('Review and verify dealer registrations',
                              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 230 - 74,
                child: Container(
                  height: 148,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AdminColors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 24, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Row(children: [
                    Expanded(child: DealerStatTile(icon: Icons.real_estate_agent_rounded, iconColor: AdminColors.primary, label: 'Total', value: '$total')),
                    DealerVDivider(),
                    Expanded(child: DealerStatTile(icon: Icons.hourglass_top_rounded, iconColor: AdminColors.warning, label: 'Pending', value: '$pending')),
                    DealerVDivider(),
                    Expanded(child: DealerStatTile(icon: Icons.verified_rounded, iconColor: AdminColors.success, label: 'Verified', value: '$verified')),
                    DealerVDivider(),
                    Expanded(child: DealerStatTile(icon: Icons.cancel_rounded, iconColor: AdminColors.rejected, label: 'Rejected', value: '$rejected')),
                  ]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class DealerVDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 54,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    color: AdminColors.border,
  );
}

class DealerStatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const DealerStatTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 30,
          width: 30,
          decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w700, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: -.4)),
      ],
    );
  }
}

class DealerGlow extends StatelessWidget {
  final double size;
  final double opacity;
  const DealerGlow(this.size, {super.key, this.opacity = 0.14});

  @override
  Widget build(BuildContext context) => Container(
    height: size,
    width: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(opacity)),
  );
}

// ================= 5-STEP PROFILE VIEW =================
class DealerProfileDialog extends StatefulWidget {
  final Dealer dealer;
  const DealerProfileDialog({super.key, required this.dealer});

  @override
  State<DealerProfileDialog> createState() => _DealerProfileDialogState();
}

class _DealerProfileDialogState extends State<DealerProfileDialog> {
  int _step = 0;
  bool _reviewing = false;

  final _stepLabels = const ['Personal', 'Business', 'Office', 'Review'];

  @override
  Widget build(BuildContext context) {
    final dealer = widget.dealer;
    final isPending = dealer.status == VerificationStatus.pending;
    final showCollapsed = !isPending && !_reviewing;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 520, maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: PremiumCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AdminColors.primary.withOpacity(0.12),
                  child: const Icon(Icons.real_estate_agent_rounded, color: AdminColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dealer.name, style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w900, fontSize: 18)),
                      const SizedBox(height: 4),
                      StatusPill(label: dealer.status.label, color: dealer.status.color),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
              ]),
              const SizedBox(height: 14),

              if (showCollapsed)
                _buildCollapsedStatus(dealer)
              else ...[
                // Step tabs — SingleChildScrollView + Row scrolls reliably even nested inside other scroll views
                SizedBox(
                  height: 44,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: List.generate(_stepLabels.length, (i) {
                        final active = _step == i;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _step = i),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: active ? AdminColors.primary : AdminColors.primary.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: active ? Colors.white : AdminColors.primary.withOpacity(0.15),
                                  child: Text('${i + 1}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: AdminColors.primary)),
                                ),
                                const SizedBox(width: 6),
                                Text(_stepLabels[i],
                                    style: TextStyle(
                                        color: active ? Colors.white : AdminColors.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12)),
                              ]),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Flexible(
                  child: SingleChildScrollView(
                    child: _buildStepBody(dealer),
                  ),
                ),

                const SizedBox(height: 14),
                Row(children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _step--),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _step < _stepLabels.length - 1
                          ? () => setState(() => _step++)
                          : () => Navigator.pop(context),
                      child: Text(_step < _stepLabels.length - 1 ? 'Next' : 'Close Profile'),
                    ),
                  ),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedStatus(Dealer dealer) {
    final verified = dealer.status == VerificationStatus.verified;
    final color = dealer.status.color;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.22)),
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withOpacity(0.13), shape: BoxShape.circle),
              child: Icon(
                verified ? Icons.verified_rounded : Icons.cancel_rounded,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                verified ? 'This dealer has been verified' : 'This dealer has been rejected',
                style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _reviewing = true),
            icon: const Icon(Icons.rate_review_rounded, size: 19),
            label: const Text('Open for Review'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AdminColors.primary,
              side: BorderSide(color: AdminColors.primary.withOpacity(0.35)),
              backgroundColor: AdminColors.primary.withOpacity(0.04),
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepBody(Dealer dealer) {
    switch (_step) {
      case 0: // Personal
        return Column(children: [
          InfoRow(icon: Icons.person_rounded, label: 'Full Name', value: dealer.name),
          InfoRow(icon: Icons.credit_card_rounded, label: 'CNIC', value: dealer.cnic),
          InfoRow(icon: Icons.email_rounded, label: 'Email', value: dealer.email),
          InfoRow(icon: Icons.phone_rounded, label: 'Phone', value: dealer.phone),
          InfoRow(icon: Icons.location_city_rounded, label: 'City', value: dealer.city),
        ]);
      case 1: // Business
        return Column(children: [
          InfoRow(icon: Icons.business_rounded, label: 'Company / Agency', value: dealer.agency),
          InfoRow(icon: Icons.business_center_rounded, label: 'Business Type', value: dealer.businessType),
          InfoRow(icon: Icons.category_rounded, label: 'Specialization', value: dealer.specialization),
          InfoRow(icon: Icons.receipt_long_rounded, label: 'NTN Number', value: dealer.ntnNumber),
          InfoRow(icon: Icons.work_history_rounded, label: 'Years in Business', value: dealer.yearsInBusiness),
        ]);
      case 2: // Office
        return Column(children: [
          InfoRow(icon: Icons.map_rounded, label: 'Area', value: dealer.area),
          InfoRow(icon: Icons.location_on_rounded, label: 'Business Address', value: dealer.businessAddress),
          InfoRow(icon: Icons.store_rounded, label: 'Office Address', value: dealer.officeAddress),
          InfoRow(icon: Icons.phone_in_talk_rounded, label: 'Office Phone', value: dealer.officePhone),
        ]);
      default: // Review (case 3)
        return Column(children: [
          InfoRow(icon: Icons.person_rounded, label: 'Full Name', value: dealer.name),
          InfoRow(icon: Icons.business_rounded, label: 'Company', value: dealer.agency),
          InfoRow(icon: Icons.location_city_rounded, label: 'City', value: dealer.city),
          InfoRow(icon: Icons.folder_rounded, label: 'Documents', value: '${dealer.documents.length} uploaded'),
          InfoRow(icon: Icons.verified_rounded, label: 'Status', value: dealer.status.label),
        ]);
    }
  }
}