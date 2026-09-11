import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../app_routes.dart';
import '../theme/admin_theme.dart';
import 'app_snack.dart';
import 'premium_widgets.dart';

class _AdminNavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;

  const _AdminNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });
}

class AdminShell extends StatelessWidget {
  final String title;
  final int selectedIndex;
  final Widget body;

  final TextEditingController? searchController;
  final String searchHint;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onSearchSubmitted;
  final VoidCallback? onSearchClear;

  final VoidCallback? onFabTap;
  final String fabLabel;
  final IconData fabIcon;

  final bool isLoading;
  final Future<void> Function()? onRefresh;

  const AdminShell({
    super.key,
    required this.title,
    required this.selectedIndex,
    required this.body,
    this.searchController,
    this.searchHint = 'Search...',
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.onSearchClear,
    this.onFabTap,
    this.fabLabel = 'Action',
    this.fabIcon = Icons.add_rounded,
    this.isLoading = false,
    this.onRefresh,
  });

  static const double _wideBreakpoint = 800;

  static const List<_AdminNavItem> _navItems = [
    _AdminNavItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      route: AdminRoutes.dashboard,
    ),
    _AdminNavItem(
      label: 'Applicant Verification',
      icon: Icons.person_search_outlined,
      selectedIcon: Icons.person_search_rounded,
      route: AdminRoutes.applicants,
    ),
    _AdminNavItem(
      label: 'Payment Verification',
      icon: Icons.credit_card_outlined,
      selectedIcon: Icons.credit_card_rounded,
      route: AdminRoutes.payments,
    ),
    _AdminNavItem(
      label: 'Plot Management',
      icon: Icons.location_on_outlined,
      selectedIcon: Icons.location_on_rounded,
      route: AdminRoutes.plots,
    ),
    _AdminNavItem(
      label: 'Plot Visualization',
      icon: Icons.layers_outlined,
      selectedIcon: Icons.layers_rounded,
      route: AdminRoutes.plotVisualization,
    ),
    _AdminNavItem(
      label: 'Balloting',
      icon: Icons.shuffle_rounded,
      selectedIcon: Icons.shuffle_rounded,
      route: AdminRoutes.balloting,
    ),
    _AdminNavItem(
      label: 'Results',
      icon: Icons.emoji_events_outlined,
      selectedIcon: Icons.emoji_events_rounded,
      route: AdminRoutes.results,
    ),
    _AdminNavItem(
      label: 'Reports',
      icon: Icons.description_outlined,
      selectedIcon: Icons.description_rounded,
      route: AdminRoutes.reports,
    ),
    _AdminNavItem(
      label: 'Dealers',
      icon: Icons.real_estate_agent_outlined,
      selectedIcon: Icons.real_estate_agent_rounded,
      route: AdminRoutes.dealers,
    ),
    _AdminNavItem(
      label: 'Profile',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      route: AdminRoutes.profile,
    ),
  ];

  // ============================================================
  // CURRENT ROUTE
  // ============================================================

  String? _currentRoute(BuildContext context) {
    return ModalRoute.of(context)?.settings.name;
  }

  // ============================================================
  // ACTIVE SIDEBAR ITEM
  // ============================================================

  int _getSelectedIndex(BuildContext context) {
    final route = _currentRoute(context);

    if (route == null) {
      return selectedIndex;
    }

    if (route == AdminRoutes.applicantDetails) {
      return _indexOf(AdminRoutes.applicants);
    }

    if (route == AdminRoutes.addPlot) {
      return _indexOf(AdminRoutes.plots);
    }

    if (route == AdminRoutes.ballotingProcessing) {
      return _indexOf(AdminRoutes.balloting);
    }

    final index = _indexOf(route);

    return index == -1 ? selectedIndex : index;
  }

  int _indexOf(String route) {
    return _navItems.indexWhere((item) => item.route == route);
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _openRoute(BuildContext context, String route) {
    final current = _currentRoute(context);

    if (current == route) {
      return;
    }

    Navigator.of(context).pushNamed(route);
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AdminRoutes.login,
            (route) => false,
      );
    }
  }

  // ============================================================
  // REAL DHS LOGO
  // ============================================================

  Widget _brandLogo({double size = 44}) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: AdminColors.primary.withOpacity(0.10),
        shape: BoxShape.circle,
      ),
      child: Image.asset(
        'assets/logo/dhs_logo.png',
        fit: BoxFit.contain,
      ),
    );
  }

  // ============================================================
  // NOTIFICATIONS (APP BAR) — real unread count, only nav icon here
  // ============================================================

  Widget _notificationButton(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('unread', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        final label = count > 9 ? '9+' : count.toString();

        return Stack(
          clipBehavior: Clip.none,
          children: [
            LuxuryIconButton(
              icon: Icons.notifications_rounded,
              showBadge: false,
              onTap: () => _openRoute(context, AdminRoutes.notifications),
            ),
            if (count > 0)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AdminColors.background, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SIDEBAR ITEM — solid pill when active
  // ============================================================

  Widget _sidebarItem(BuildContext context, _AdminNavItem item, int index) {
    final activeIndex = _getSelectedIndex(context);
    final selected = index == activeIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openRoute(context, item.route),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: selected ? AdminColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: selected
                  ? [
                BoxShadow(
                  color: AdminColors.primary.withOpacity(0.30),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: 20,
                  color: selected ? AdminColors.white : AdminColors.greyText,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? AdminColors.white : AdminColors.darkText,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION LABEL — "MAIN MENU"
  // ============================================================

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 6, 26, 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AdminColors.greyText,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM PROFILE — real admin name (live from Firestore) + logout
  // ============================================================

  Widget _bottomProfile(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: uid != null
            ? FirebaseFirestore.instance.collection('admins').doc(uid).snapshots()
            : null,
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          final nameFromFirestore = data?['name']?.toString().trim();

          String name;
          if (nameFromFirestore != null && nameFromFirestore.isNotEmpty) {
            name = nameFromFirestore;
          } else {
            final authName = user?.displayName;
            final authEmail = user?.email;
            name = (authName != null && authName.trim().isNotEmpty)
                ? authName
                : (authEmail != null && authEmail.isNotEmpty ? authEmail.split('@').first : 'Admin');
          }

          final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'A';

          return Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AdminColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AdminColors.primary,
                  child: Text(
                    initial,
                    style: const TextStyle(color: AdminColors.white, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AdminColors.darkText, fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Super Admin',
                        style: TextStyle(color: AdminColors.greyText, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Logout',
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout_rounded, size: 19, color: AdminColors.greyText),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // DESKTOP SIDEBAR
  // ============================================================

  Widget _desktopSidebar(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: AdminColors.white,
        border: Border(
          right: BorderSide(color: AdminColors.primary.withOpacity(0.07), width: 1),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 18, 16),
              child: Row(
                children: [
                  _brandLogo(),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DHS Admin',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AdminColors.darkText, fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Digital Housing Society',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AdminColors.greyText, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 1, color: AdminColors.primary.withOpacity(0.07)),
            ),
            _sectionLabel('MAIN MENU'),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 15),
                physics: const BouncingScrollPhysics(),
                itemCount: _navItems.length,
                itemBuilder: (context, index) => _sidebarItem(context, _navItems[index], index),
              ),
            ),
            _bottomProfile(context),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE DRAWER
  // ============================================================

  Widget _mobileDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AdminColors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 14, 14),
              child: Row(
                children: [
                  _brandLogo(),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DHS Admin',
                          style: TextStyle(color: AdminColors.darkText, fontSize: 15, fontWeight: FontWeight.w900),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Housing Society',
                          style: TextStyle(color: AdminColors.greyText, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: AdminColors.greyText),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AdminColors.primary.withOpacity(0.07)),
            _sectionLabel('MAIN MENU'),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: _navItems.length,
                itemBuilder: (context, index) => _sidebarItem(context, _navItems[index], index),
              ),
            ),
            _bottomProfile(context),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= _wideBreakpoint;

    final mainContent = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          children: [
            if (searchController != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: PremiumSearchBar(
                  controller: searchController,
                  hintText: searchHint,
                  onChanged: onSearchChanged,
                  onSubmitted: onSearchSubmitted,
                  onClear: onSearchClear,
                ),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isLoading ? const LoadingState() : body,
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        titleSpacing: 20,
        title: Text(title),
        actions: [
          _notificationButton(context),
          const SizedBox(width: 16),
        ],
      ),
      drawer: isWide ? null : _mobileDrawer(context),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-$title',
        onPressed: onFabTap ?? () => showAdminSnack(context, '$fabLabel clicked'),
        backgroundColor: AdminColors.primary,
        foregroundColor: AdminColors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        icon: Icon(fabIcon),
        label: Text(fabLabel, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: isWide
          ? Row(
        children: [
          _desktopSidebar(context),
          Expanded(child: mainContent),
        ],
      )
          : mainContent,
    );
  }
}