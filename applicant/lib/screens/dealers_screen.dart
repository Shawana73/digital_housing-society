import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/firestore_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/demo_data.dart';
import '../utils/app_text_styles.dart';
import '../widgets/responsive_shell.dart';

class DealersScreen extends StatefulWidget {
  const DealersScreen({super.key});

  @override
  State<DealersScreen> createState() => _DealersScreenState();
}

class _DealersScreenState extends State<DealersScreen> {
  final FirestoreService _service = FirestoreService();

  String _query = '';
  String _city = 'All';
  String _specialization = 'All';

  @override
  Widget build(BuildContext context) {
    return DhsResponsiveShell(
      currentRoute: AppConstants.dealersRoute,
      mobileTitle: 'Verified Dealers',
      backgroundColor: const Color(0xFFF5F7FC),
      child: SafeArea(
        top: false,
        bottom: false,
        child: StreamBuilder<QuerySnapshot>(
          stream: _service.getVerifiedDealers(),
          builder: (context, snapshot) {
            final firestoreDealers = [...?snapshot.data?.docs].map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return <String, dynamic>{...data, '_id': doc.id};
            }).toList();

            // Keep the applicant demo complete before the admin module is
            // connected. Once verified dealer records exist in Firestore,
            // those records automatically replace this preview data.
            final allDealers = firestoreDealers.isNotEmpty
                ? firestoreDealers
                : DemoData.dealers
                    .map((dealer) => Map<String, dynamic>.from(dealer))
                    .toList();

            final cities = _options(allDealers, 'city');
            final specializations =
                _specializationOptions(allDealers);

            final dealers = allDealers.where((dealer) {
              final haystack = [
                dealer['name'],
                dealer['fullName'],
                dealer['companyName'],
                dealer['city'],
                dealer['specialization'],
                dealer['licenseNumber'],
              ].join(' ').toLowerCase();

              final city = (dealer['city'] ?? '').toString();
              final specialization =
                  (dealer['specialization'] ?? '').toString();

              final matchesQuery =
                  haystack.contains(_query.toLowerCase());
              final matchesCity = _city == 'All' || city == _city;
              final matchesSpecialization =
                  _specialization == 'All' ||
                      specialization
                          .toLowerCase()
                          .contains(_specialization.toLowerCase());

              return matchesQuery &&
                  matchesCity &&
                  matchesSpecialization;
            }).toList();

            return Column(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: _DealersHeader(
                              onBellTap: () => Navigator.pushNamed(
                                context,
                                AppConstants.notificationsRoute,
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                              child: _DealerSearchBox(
                                onChanged: (value) =>
                                    setState(() => _query = value.trim()),
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                              child: _DealerFilters(
                                  city: _city,
                                  specialization: _specialization,
                                  cities: cities,
                                  specializations: specializations,
                                  onCity: (value) =>
                                      setState(() => _city = value),
                                  onSpecialization: (value) =>
                                      setState(() => _specialization = value),
                                  onReset: () => setState(() {
                                    _city = 'All';
                                    _specialization = 'All';
                                  }),
                                ),
                              ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(18, 0, 18, 14),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: FilledButton.icon(
                                    onPressed: () => Navigator.pushNamed(
                                      context,
                                      AppConstants.dealerRegistrationRoute,
                                    ),
                                    icon: const Icon(
                                      Icons.add_business_rounded,
                                    ),
                                    label:
                                        const Text('Register as a Dealer'),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 15,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              snapshot.data == null)
                            const SliverToBoxAdapter(
                              child: LinearProgressIndicator(
                                minHeight: 2,
                                color: AppColors.primaryPurple,
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                          if (dealers.isEmpty)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: _EmptyDealers(),
                            )
                          else
                            SliverPadding(
                              padding:
                                  const EdgeInsets.fromLTRB(18, 0, 18, 18),
                              sliver: SliverLayoutBuilder(
                                builder: (context, constraints) {
                                  final width = constraints.crossAxisExtent;
                                  final columns = width >= 980 ? 2 : 1;

                                  return SliverGrid(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final dealer = dealers[index];
                                        return _DealerCard(
                                          data: dealer,
                                          onViewProfile: () =>
                                              _showDealerProfile(dealer),
                                          onContact: () =>
                                              _showContactSheet(dealer),
                                        );
                                      },
                                      childCount: dealers.length,
                                    ),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      mainAxisExtent: 260,
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  EdgeInsets.fromLTRB(18, 0, 18, 18),
                              child: _TrustStrip(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<String> _options(
    List<Map<String, dynamic>> rows,
    String key,
  ) {
    final values = rows
        .map((row) => (row[key] ?? '').toString().trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...values];
  }

  List<String> _specializationOptions(
    List<Map<String, dynamic>> rows,
  ) {
    final values = <String>{};

    for (final row in rows) {
      final raw = (row['specialization'] ?? '').toString();
      for (final part in raw.split(',')) {
        final value = part.trim();
        if (value.isNotEmpty) values.add(value);
      }
    }

    final result = values.toList()..sort();
    return ['All', ...result];
  }

  void _showDealerProfile(Map<String, dynamic> dealer) {
    final company =
        (dealer['companyName'] ?? dealer['name'] ?? 'DHS Dealer')
            .toString();
    final license =
        (dealer['licenseNumber'] ?? dealer['licenseId'] ?? '-').toString();
    final city = (dealer['city'] ?? '-').toString();
    final specialization =
        (dealer['specialization'] ?? 'Property Services').toString();
    final phone = (dealer['phone'] ?? '-').toString();
    final email = (dealer['email'] ?? '-').toString();
    final address =
        (dealer['businessAddress'] ?? dealer['address'] ?? '-').toString();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: .72,
          minChildSize: .55,
          maxChildSize: .92,
          builder: (context, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8DCE8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      _DealerLogo(
                        company: company,
                        large: true,
                        logoAsset: (dealer['logoAsset'] ?? '').toString(),
                        logoUrl: (dealer['logoUrl'] ?? '').toString(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    company,
                                    style: AppTextStyles.headingSmall,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.verified_rounded,
                                  color: Color(0xFF1F63D6),
                                  size: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'License ID: $license',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _profileRow(Icons.location_on_outlined, 'City', city),
                  _profileRow(
                    Icons.business_center_outlined,
                    'Specialization',
                    specialization,
                  ),
                  _profileRow(Icons.phone_outlined, 'Phone', phone),
                  _profileRow(Icons.email_outlined, 'Email', email),
                  _profileRow(
                    Icons.store_mall_directory_outlined,
                    'Business Address',
                    address,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF2A5BD8),
                            Color(0xFF843CEA),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showContactSheet(dealer);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        icon: const Icon(Icons.call_outlined),
                        label: const Text('Contact Dealer'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showContactSheet(Map<String, dynamic> dealer) {
    final company =
        (dealer['companyName'] ?? dealer['name'] ?? 'DHS Dealer')
            .toString();
    final phone = (dealer['phone'] ?? '').toString();
    final email = (dealer['email'] ?? '').toString();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8DCE8),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Contact $company',
                textAlign: TextAlign.center,
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: 18),
              if (phone.isNotEmpty)
                _ContactTile(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: phone,
                  onCopy: () => _copyToClipboard(phone),
                ),
              if (email.isNotEmpty)
                _ContactTile(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: email,
                  onCopy: () => _copyToClipboard(email),
                ),
              if (phone.isEmpty && email.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    'Contact information is not available yet.',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _copyToClipboard(String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EDFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 19,
              color: AppColors.primaryPurple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.captionText,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.labelBold,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class _DealersHeader extends StatelessWidget {
  const _DealersHeader({required this.onBellTap});

  final VoidCallback onBellTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 42),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF14499E),
            Color(0xFF293CC4),
            Color(0xFF7337D7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 10,
            bottom: -8,
            child: Opacity(
              opacity: .12,
              child: Icon(
                Icons.location_city_rounded,
                size: 180,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            right: 44,
            bottom: 0,
            child: Container(
              width: 72,
              height: 82,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: .22),
                    Colors.white.withValues(alpha: .07),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .28),
                ),
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(
                      'assets/logos/dhs_logo.png',
                      width: 150,
                      height: 58,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .16),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: IconButton(
                            onPressed: onBellTap,
                            icon: const Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 9,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF5B64),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Verified Dealers',
                style: AppTextStyles.headingLarge.copyWith(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Connect with trusted & verified DHS dealers.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white.withValues(alpha: .9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DealerSearchBox extends StatelessWidget {
  const _DealerSearchBox({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      shadowColor: const Color(0xFF6671D7).withValues(alpha: .15),
      borderRadius: BorderRadius.circular(22),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: 'Search dealers or companies...',
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF7F8AA3),
          ),
          suffixIcon: const Icon(
            Icons.tune_rounded,
            color: Color(0xFF5360A4),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: Color(0xFFE7EAF2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide:
                const BorderSide(color: AppColors.primaryPurple, width: 1.4),
          ),
        ),
      ),
    );
  }
}

class _DealerFilters extends StatelessWidget {
  const _DealerFilters({
    required this.city,
    required this.specialization,
    required this.cities,
    required this.specializations,
    required this.onCity,
    required this.onSpecialization,
    required this.onReset,
  });

  final String city;
  final String specialization;
  final List<String> cities;
  final List<String> specializations;
  final ValueChanged<String> onCity;
  final ValueChanged<String> onSpecialization;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _DealerFilterChip(
          icon: Icons.location_on_outlined,
          label: city == 'All' ? 'City' : city,
          options: cities,
          value: city,
          onChanged: onCity,
        ),
        _DealerFilterChip(
          icon: Icons.business_center_outlined,
          label: specialization == 'All'
              ? 'Specialization'
              : specialization,
          options: specializations,
          value: specialization,
          onChanged: onSpecialization,
        ),
        const _VerifiedOnlyChip(),
        TextButton(
          onPressed: onReset,
          child: const Text('Reset'),
        ),
      ],
    );
  }
}

class _DealerFilterChip extends StatelessWidget {
  const _DealerFilterChip({
    required this.icon,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (context) => options
          .map(
            (option) => PopupMenuItem<String>(
              value: option,
              child: Text(option),
            ),
          )
          .toList(),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE5E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19, color: const Color(0xFF48526B)),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF30394F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: Color(0xFF48526B),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerifiedOnlyChip extends StatelessWidget {
  const _VerifiedOnlyChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            size: 19,
            color: Color(0xFF48526B),
          ),
          const SizedBox(width: 8),
          Text(
            'Verified Only',
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF30394F),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 5),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: Color(0xFF48526B),
          ),
        ],
      ),
    );
  }
}

class _DealerCard extends StatelessWidget {
  const _DealerCard({
    required this.data,
    required this.onViewProfile,
    required this.onContact,
  });

  final Map<String, dynamic> data;
  final VoidCallback onViewProfile;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    final company =
        (data['companyName'] ?? data['name'] ?? 'DHS Dealer').toString();
    final license =
        (data['licenseNumber'] ?? data['licenseId'] ?? 'DHS Verified')
            .toString();
    final city = (data['city'] ?? '-').toString();
    final phone = (data['phone'] ?? '-').toString();
    final specialization =
        (data['specialization'] ?? 'Residential & Commercial Plots')
            .toString();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6EAF2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6671D7).withValues(alpha: .08),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DealerLogo(
                  company: company,
                  logoAsset: (data['logoAsset'] ?? '').toString(),
                  logoUrl: (data['logoUrl'] ?? '').toString(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              company,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.headingSmall.copyWith(
                                fontSize: 18,
                                color: const Color(0xFF101828),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF1F63D6),
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'License ID: $license',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: const Color(0xFF4D5871),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _DealerMeta(
                        icon: Icons.location_on_outlined,
                        text: city,
                      ),
                      const SizedBox(height: 8),
                      _DealerMeta(
                        icon: Icons.business_center_outlined,
                        text: specialization,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F5FA),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: IconButton(
                        onPressed: onContact,
                        icon: const Icon(
                          Icons.phone_outlined,
                          color: Color(0xFF33406A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      phone,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: const Color(0xFF5E687E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: onViewProfile,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF263D91),
                      side: const BorderSide(color: Color(0xFFACB7D9)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.person_outline_rounded, size: 19),
                    label: const Text('View Profile'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF265BD8),
                          Color(0xFF833BE9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: FilledButton.icon(
                      onPressed: onContact,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.call_outlined, size: 19),
                      label: const Text('Contact'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DealerLogo extends StatelessWidget {
  const _DealerLogo({
    required this.company,
    this.large = false,
    this.logoAsset = '',
    this.logoUrl = '',
  });

  final String company;
  final bool large;
  final String logoAsset;
  final String logoUrl;

  @override
  Widget build(BuildContext context) {
    final index = company.codeUnits.fold<int>(0, (a, b) => a + b) % 3;
    final gradients = <List<Color>>[
      [const Color(0xFF081A38), const Color(0xFF102C58)],
      [const Color(0xFFF5F1E8), const Color(0xFFE7DFCF)],
      [const Color(0xFF073A3D), const Color(0xFF0B5756)],
    ];
    final iconColors = <Color>[
      Colors.white,
      const Color(0xFFB1842C),
      const Color(0xFFE9C269),
    ];

    final size = large ? 86.0 : 82.0;

    final imageRadius = BorderRadius.circular(20);

    if (logoUrl.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: imageRadius,
        child: Image.network(
          logoUrl.trim(),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackLogo(
            size: size,
            index: index,
            gradients: gradients,
            iconColors: iconColors,
          ),
        ),
      );
    }

    if (logoAsset.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: imageRadius,
        child: Image.asset(
          logoAsset.trim(),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackLogo(
            size: size,
            index: index,
            gradients: gradients,
            iconColors: iconColors,
          ),
        ),
      );
    }

    return _fallbackLogo(
      size: size,
      index: index,
      gradients: gradients,
      iconColors: iconColors,
    );
  }

  Widget _fallbackLogo({
    required double size,
    required int index,
    required List<List<Color>> gradients,
    required List<Color> iconColors,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradients[index],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.apartment_rounded,
            size: large ? 42 : 36,
            color: iconColors[index],
          ),
          Positioned(
            bottom: 8,
            left: 5,
            right: 5,
            child: Text(
              _shortCompany(company),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.captionText.copyWith(
                color: index == 1
                    ? const Color(0xFF2B2B2B)
                    : Colors.white,
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                letterSpacing: .4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _shortCompany(String value) {
    final words = value.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return 'DHS';
    if (words.length == 1) {
      return words.first.length <= 10
          ? words.first.toUpperCase()
          : words.first.substring(0, 10).toUpperCase();
    }
    return words.take(2).join(' ').toUpperCase();
  }
}

class _DealerMeta extends StatelessWidget {
  const _DealerMeta({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: const Color(0xFF61709A),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF667085),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EAF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EDFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryPurple,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.captionText),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  style: AppTextStyles.labelBold,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Copy',
          ),
        ],
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            size: 18,
            color: Color(0xFF4054B2),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'All dealers are verified by DHS. Your trust, our priority.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFF5D6890),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDealers extends StatelessWidget {
  const _EmptyDealers();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(34),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: Color(0xFFF0EDFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.groups_outlined,
              color: AppColors.primaryPurple,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No verified dealers found',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: 7),
          Text(
            'Try changing the search or filter options.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}
