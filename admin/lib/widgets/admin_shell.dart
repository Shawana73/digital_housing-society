import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_routes.dart';
import '../theme/admin_theme.dart';
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

// Layered wave used as a decorative, light-toned base behind the
// sidebar's profile card — purely cosmetic, no state or logic.
// Two clippers with different curve shapes/phases are stacked to
// give a soft parallax "hill" look instead of one flat curve.
class _SidebarWaveClipperBack extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height * 0.55);

    path.quadraticBezierTo(
      size.width * 0.22,
      size.height * 0.18,
      size.width * 0.50,
      size.height * 0.40,
    );
    path.quadraticBezierTo(
      size.width * 0.78,
      size.height * 0.62,
      size.width,
      size.height * 0.30,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _SidebarWaveClipperFront extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height * 0.72);

    path.quadraticBezierTo(
      size.width * 0.28,
      size.height * 0.38,
      size.width * 0.58,
      size.height * 0.58,
    );
    path.quadraticBezierTo(
      size.width * 0.84,
      size.height * 0.76,
      size.width,
      size.height * 0.48,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', false);

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AdminRoutes.login,
            (route) => false,
      );
    }
  }

  // ============================================================
  // BRAND LOGO — bigger, solid backdrop so it pops on any surface
  // ============================================================

  Widget _brandLogo({double size = 58}) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 14,
            spreadRadius: -2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Image.asset(
        'assets/logo/dhs_logo.png',
        fit: BoxFit.contain,
      ),
    );
  }

  // ============================================================
  // BRAND HEADER CARD — purple "bookend" to match the base wave,
  // logo + text kept high-contrast (white) so they stay legible
  // ============================================================

  Widget _brandHeaderCard({String subtitle = 'Digital Housing Society'}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Soft purple glow around the card
        Positioned(
          top: -18,
          left: -18,
          right: -18,
          bottom: -18,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: AdminColors.primary.withOpacity(0.28),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AdminColors.primary,
                AdminColors.primary.withOpacity(0.84),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AdminColors.primary.withOpacity(0.32),
                blurRadius: 20,
                spreadRadius: -6,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _brandLogo(),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DHS Admin',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // NOTIFICATIONS (APP BAR)
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
              onTap: () => _openRoute(
                context,
                AdminRoutes.notifications,
              ),
            ),
            if (count > 0)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AdminColors.background,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SIDEBAR ITEM — refined "floating pill" premium style
  // ============================================================

  Widget _sidebarItem(
      BuildContext context,
      _AdminNavItem item,
      int index,
      ) {
    final activeIndex = _getSelectedIndex(context);
    final selected = index == activeIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 3.5,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: AdminColors.primary.withOpacity(0.10),
          highlightColor: AdminColors.primary.withOpacity(0.05),
          hoverColor: AdminColors.primary.withOpacity(0.045),
          onTap: () => _openRoute(context, item.route),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AdminColors.primary,
                  AdminColors.primary.withOpacity(0.86),
                ],
              )
                  : LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.0),
                  Colors.white.withOpacity(0.0),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? AdminColors.primary.withOpacity(0.15)
                    : Colors.white.withOpacity(0.0),
                width: 1,
              ),
              boxShadow: selected
                  ? [
                BoxShadow(
                  color: AdminColors.primary.withOpacity(0.28),
                  blurRadius: 20,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ]
                  : [],
            ),
            child: Row(
              children: [
                // Icon container — softly rounded "chip"
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withOpacity(0.16)
                        : AdminColors.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    selected ? item.selectedIcon : item.icon,
                    size: 18,
                    color: selected
                        ? AdminColors.white
                        : AdminColors.greyText,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    style: TextStyle(
                      color: selected
                          ? AdminColors.white
                          : AdminColors.darkText,
                      fontSize: 13,
                      fontWeight:
                      selected ? FontWeight.w800 : FontWeight.w600,
                      letterSpacing: selected ? 0.05 : 0,
                    ),
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // Active dot instead of a busy arrow — quieter, cleaner
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: selected ? 1 : 0,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
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
  // BOTTOM PROFILE — refined glass card
  // ============================================================

  Widget _bottomProfile(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        14,
        10,
        14,
        16,
      ),
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: uid != null
            ? FirebaseFirestore.instance
            .collection('admins')
            .doc(uid)
            .snapshots()
            : null,
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          final nameFromFirestore =
          data?['name']?.toString().trim();

          String name;

          if (nameFromFirestore != null &&
              nameFromFirestore.isNotEmpty) {
            name = nameFromFirestore;
          } else {
            final authName = user?.displayName;
            final authEmail = user?.email;

            name = (authName != null &&
                authName.trim().isNotEmpty)
                ? authName
                : (authEmail != null &&
                authEmail.isNotEmpty
                ? authEmail.split('@').first
                : 'Admin');
          }

          final initial = name.trim().isNotEmpty
              ? name.trim()[0].toUpperCase()
              : 'A';

          return Container(
            padding: const EdgeInsets.fromLTRB(
              12,
              12,
              9,
              12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AdminColors.primary.withOpacity(0.12),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 18,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AdminColors.primary,
                        AdminColors.primary.withOpacity(0.45),
                      ],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: AdminColors.primary,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: AdminColors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 11),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AdminColors.darkText,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.green.shade400,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green
                                      .withOpacity(0.5),
                                  blurRadius: 4,
                                  spreadRadius: 0.5,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Super Admin',
                            style: TextStyle(
                              color: AdminColors.greyText,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Material(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _logout(context),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.logout_rounded,
                        size: 17,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // NAV LIST — shared between desktop sidebar and mobile drawer
  // ============================================================

  Widget _navList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 6, bottom: 15),
      physics: const BouncingScrollPhysics(),
      itemCount: _navItems.length,
      itemBuilder: (context, index) {
        return _sidebarItem(context, _navItems[index], index);
      },
    );
  }

  // ============================================================
  // DECORATIVE BASE WAVE — the extra "beauty" touch that sits
  // behind the profile card, purely visual, no logic attached
  // ============================================================

  Widget _sidebarBaseWave({required double height}) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        children: [
          // Back layer — very light lavender
          Positioned.fill(
            child: ClipPath(
              clipper: _SidebarWaveClipperBack(),
              child: Container(
                color: const Color(0xFFF1E9FF),
              ),
            ),
          ),
          // Front layer — slightly deeper, still light, pastel purple
          Positioned.fill(
            child: ClipPath(
              clipper: _SidebarWaveClipperFront(),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE3D3FF),
                      Color(0xFFD5BEFF),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WAVE FOOTER — the base wave plus a soft dreamy purple glow
  // behind it (clipped so it never bleeds into the white nav area
  // above), then the solid profile card floating on top
  // ============================================================

  Widget _sidebarWaveFooter(BuildContext context, {required double height}) {
    return ClipRect(
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Dreamy glow — left
          Positioned(
            bottom: -30,
            left: -45,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD8C3FF).withOpacity(0.28),
                ),
              ),
            ),
          ),
          // Dreamy glow — right
          Positioned(
            bottom: -20,
            right: -45,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 34, sigmaY: 34),
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFBFA0FF).withOpacity(0.24),
                ),
              ),
            ),
          ),
          _sidebarBaseWave(height: height),
          _bottomProfile(context),
        ],
      ),
    );
  }

  // ============================================================
  // DESKTOP SIDEBAR
  // ============================================================
  Widget _desktopSidebar(BuildContext context) {
    return Container(
      width: 264,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          right: BorderSide(
            color: Color(0xFFEDE9F5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 24,
            spreadRadius: -12,
            offset: const Offset(8, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // BRAND HEADER CARD
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
              child: _brandHeaderCard(),
            ),

            // NAVIGATION
            Expanded(child: _navList(context)),

            // WAVE FOOTER (glow + wave + profile)
            _sidebarWaveFooter(context, height: 130),
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
      elevation: 18,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // BRAND HEADER CARD
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _brandHeaderCard(subtitle: 'Housing Society'),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: AdminColors.primary.withOpacity(0.07),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(context).pop(),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.close_rounded,
                            size: 17,
                            color: AdminColors.darkText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // NAVIGATION
            Expanded(child: _navList(context)),

            // WAVE FOOTER (glow + wave + profile)
            _sidebarWaveFooter(context, height: 122),
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
                padding: const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  16,
                ),
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
                child: isLoading
                    ? const LoadingState()
                    : body,
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
      floatingActionButton: onFabTap == null
          ? null
          : FloatingActionButton.extended(
        heroTag: 'fab-$title',
        onPressed: onFabTap,
        backgroundColor: AdminColors.primary,
        foregroundColor: AdminColors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        icon: Icon(fabIcon),
        label: Text(
          fabLabel,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: isWide
          ? Row(
        children: [
          _desktopSidebar(context),
          Expanded(
            child: mainContent,
          ),
        ],
      )
          : mainContent,
    );
  }
}