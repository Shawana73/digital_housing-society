import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/premium_widgets.dart';

class DetailsTabStrip extends StatelessWidget {
  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onSelected;
  const DetailsTabStrip({super.key, required this.tabs, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 22),
        itemBuilder: (context, i) {
          final active = i == selected;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tabs[i],
                    style: TextStyle(
                        color: active ? AdminColors.primary : AdminColors.greyText,
                        fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                        fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  height: 3,
                  width: 28,
                  decoration: BoxDecoration(
                    color: active ? AdminColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DocumentsTab extends StatelessWidget {
  final List<ApplicantDocument> documents;
  final void Function(String title, IconData icon) onPreview;

  const DocumentsTab({
    super.key,
    required this.documents,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final docs = documents;

    if (docs.isEmpty) {
      return PremiumCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              Icons.folder_off_rounded,
              color: AdminColors.greyText,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No documents have been uploaded by this applicant.',
                style: TextStyle(
                  color: AdminColors.greyText,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Uploaded Documents',
          style: TextStyle(
            color: AdminColors.darkText,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 12),

        for (int i = 0; i < docs.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: DocTile(
                      doc: docs[i],
                      onTap: () => onPreview(
                        docs[i].title,
                        docs[i].icon,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: i + 1 < docs.length
                        ? DocTile(
                      doc: docs[i + 1],
                      onTap: () => onPreview(
                        docs[i + 1].title,
                        docs[i + 1].icon,
                      ),
                    )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 6),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => showAdminSnack(
                  context,
                  'Download feature will be connected next.',
                ),
                icon: const Icon(
                  Icons.download_rounded,
                  size: 18,
                ),
                label: const Text('Download'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => onPreview(
                  'All Documents',
                  Icons.folder_copy_rounded,
                ),
                icon: const Icon(
                  Icons.fullscreen_rounded,
                  size: 18,
                ),
                label: const Text('View Full'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class DocTile extends StatelessWidget {
  final ApplicantDocument doc;
  final VoidCallback onTap;
  const DocTile({super.key, required this.doc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = doc.verified ? AdminColors.success : AdminColors.warning;
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(color: AdminColors.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(11)),
              child: Icon(doc.icon, color: AdminColors.primary, size: 19),
            ),
            const Spacer(),
            RoundGhostIcon(icon: Icons.visibility_outlined, onTap: onTap),
          ]),
          const SizedBox(height: 10),
          Text(doc.title,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w800, fontSize: 12.5)),
          const SizedBox(height: 4),
          Text('${doc.fileType.toUpperCase()} • ${doc.fileSize} bytes',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 10.5)),
          const SizedBox(height: 8),
          StatusPill(label: doc.verified ? 'Verified' : 'Pending', color: color),
        ],
      ),
    );
  }
}

class RoundGhostIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const RoundGhostIcon({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: AdminColors.background,
    borderRadius: BorderRadius.circular(9),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 28,
        width: 28,
        alignment: Alignment.center,
        child: Icon(icon, size: 14, color: AdminColors.darkText),
      ),
    ),
  );
}

class PersonalInfoTab extends StatelessWidget {
  final dynamic viewModel; // ApplicantDetailsViewModel

  const PersonalInfoTab({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(icon: Icons.badge_rounded, label: 'Applicant ID', value: viewModel.applicationId),
          InfoRow(icon: Icons.person_rounded, label: 'Full Name', value: viewModel.fullName),
          InfoRow(icon: Icons.credit_card_rounded, label: 'CNIC', value: viewModel.cnic),
          InfoRow(icon: Icons.phone_rounded, label: 'Phone', value: viewModel.phone),
          InfoRow(icon: Icons.email_rounded, label: 'Email', value: viewModel.email),
          InfoRow(icon: Icons.location_on_rounded, label: 'Address', value: viewModel.address),
          InfoRow(icon: Icons.location_city_rounded, label: 'City', value: viewModel.city),
          InfoRow(icon: Icons.cake_rounded, label: 'Date of Birth', value: viewModel.dateOfBirth),
          InfoRow(icon: Icons.category_rounded, label: 'Application Type', value: viewModel.applicationType),
          InfoRow(icon: Icons.confirmation_number_rounded, label: 'Serial Number', value: viewModel.serialNumber),
          InfoRow(icon: Icons.payments_rounded, label: 'Application Fee', value: viewModel.fee),
          InfoRow(icon: Icons.verified_rounded, label: 'Application Status', value: viewModel.applicationStatus),
        ],
      ),
    );
  }
}

class PaymentInfoTab extends StatelessWidget {
  const PaymentInfoTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const PremiumCard(
      padding: EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(icon: Icons.receipt_long_rounded, label: 'Transaction ID', value: 'DH-882913'),
          InfoRow(icon: Icons.payments_rounded, label: 'Amount Paid', value: 'PKR 450,000'),
          InfoRow(icon: Icons.account_balance_rounded, label: 'Payment Method', value: 'Bank Transfer'),
          InfoRow(icon: Icons.event_rounded, label: 'Payment Date', value: '28 Jun 2026'),
        ],
      ),
    );
  }
}

class ActivityLogTab extends StatelessWidget {
  const ActivityLogTab({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = [
      ('Application submitted', '28 Jun 2026, 9:02 AM'),
      ('CNIC documents uploaded', '28 Jun 2026, 9:14 AM'),
      ('Admin reviewed profile', '28 Jun 2026, 11:30 AM'),
    ];
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < entries.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == entries.length - 1 ? 0 : 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    height: 8,
                    width: 8,
                    decoration: const BoxDecoration(color: AdminColors.primary, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entries[i].$1,
                            style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w800, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(entries[i].$2,
                            style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class DetailsMiniLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final int maxLines;
  const DetailsMiniLine({super.key, required this.icon, required this.text, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AdminColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 11.5, height: 1.3)),
        ),
      ],
    );
  }
}

class DetailsMetaTile extends StatelessWidget {
  final String label;
  final String value;
  const DetailsMetaTile({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600, fontSize: 11)),
        const SizedBox(height: 3),
        Text(value,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AdminColors.darkText, fontWeight: FontWeight.w800, fontSize: 12.5)),
      ],
    );
  }
}

class DetailsDivider extends StatelessWidget {
  const DetailsDivider({super.key});
  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    color: AdminColors.primary.withOpacity(0.07),
  );
}