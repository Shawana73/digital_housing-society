import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/app_assets.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';

/// Shared DHS navigation shell.
///
/// Desktop/Chrome: fixed left sidebar.
/// Mobile: the exact same destinations are shown in a slide-out drawer.
/// This intentionally replaces the old screen-specific bottom navigation bars.
class DhsResponsiveShell extends StatelessWidget {
  const DhsResponsiveShell({
    super.key,
    required this.currentRoute,
    required this.child,
    this.backgroundColor = AppColors.pageBackground,
    this.mobileTitle = 'Digital Housing Society',
  });

  final String currentRoute;
  final Widget child;
  final Color backgroundColor;
  final String mobileTitle;

  static const double desktopBreakpoint = 980;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= desktopBreakpoint;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 252,
                child: DhsNavigationPanel(
                  currentRoute: currentRoute,
                  isDrawer: false,
                ),
              ),
              const VerticalDivider(
                width: 1,
                thickness: 1,
                color: Color(0xFFE8E7F2),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: Drawer(
        width: MediaQuery.sizeOf(context).width.clamp(280.0, 340.0),
        child: SafeArea(
          child: DhsNavigationPanel(
            currentRoute: currentRoute,
            isDrawer: true,
          ),
        ),
      ),
      appBar: AppBar(
        toolbarHeight: 66,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: AppColors.primaryText,
        titleSpacing: 4,
        title: Row(
          children: [
            Image.asset(
              AppAssets.logo,
              height: 35,
              width: 35,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.apartment_rounded,
                color: AppColors.deepPurple,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                mobileTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        actions: [
          _MobileNotificationButton(),
          const SizedBox(width: 4),
          _MobileInitialsAvatar(),
          const SizedBox(width: 12),
        ],
      ),
      body: child,
    );
  }
}

class DhsNavigationPanel extends StatelessWidget {
  const DhsNavigationPanel({
    super.key,
    required this.currentRoute,
    required this.isDrawer,
  });

  final String currentRoute;
  final bool isDrawer;

  static const List<_DhsNavDestination> _destinations = [
    _DhsNavDestination(
      label: 'Dashboard',
      icon: Icons.grid_view_rounded,
      route: AppConstants.dashboardRoute,
    ),
    _DhsNavDestination(
      label: 'Explore Plots',
      icon: Icons.travel_explore_rounded,
      route: AppConstants.plotsRoute,
    ),
    _DhsNavDestination(
      label: 'Static Plot Map',
      icon: Icons.map_outlined,
      route: AppConstants.mapRoute,
    ),
    _DhsNavDestination(
      label: 'Applications',
      icon: Icons.fact_check_outlined,
      route: AppConstants.applicationRoute,
    ),
    _DhsNavDestination(
      label: 'Balloting',
      icon: Icons.casino_outlined,
      route: AppConstants.ballotingRoute,
    ),
    _DhsNavDestination(
      label: 'Balloting Result',
      icon: Icons.emoji_events_outlined,
      route: AppConstants.resultRoute,
    ),
    _DhsNavDestination(
      label: 'Dealers',
      icon: Icons.groups_2_outlined,
      route: AppConstants.dealersRoute,
    ),
    _DhsNavDestination(
      label: 'Register as Dealer',
      icon: Icons.add_business_outlined,
      route: AppConstants.dealerRegistrationRoute,
    ),
    _DhsNavDestination(
      label: 'Payments',
      icon: Icons.account_balance_wallet_outlined,
      route: AppConstants.paymentRoute,
    ),
    _DhsNavDestination(
      label: 'Documents',
      icon: Icons.folder_copy_outlined,
      route: AppConstants.uploadRoute,
    ),
    _DhsNavDestination(
      label: 'Messages',
      icon: Icons.mark_chat_unread_outlined,
      route: AppConstants.notificationsRoute,
    ),
    _DhsNavDestination(
      label: 'Favourites',
      icon: Icons.favorite_border_rounded,
      route: AppConstants.favouritesRoute,
    ),
    _DhsNavDestination(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      route: AppConstants.profileRoute,
    ),
    _DhsNavDestination(
      label: 'Settings',
      icon: Icons.settings_outlined,
      route: AppConstants.settingsRoute,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Column(
        children: [
          _brand(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              itemCount: _destinations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final destination = _destinations[index];
                final selected = currentRoute == destination.route;
                return _NavTile(
                  destination: destination,
                  selected: selected,
                  onTap: () => _navigate(context, destination.route),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFF3F0FF),
                        Color(0xFFEFF5FF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE3DDFC)),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFFE9E2FF),
                        child: Icon(
                          Icons.support_agent_rounded,
                          color: AppColors.deepPurple,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Need Help?',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryText,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'DHS support is here for you.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Logout'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.errorRed,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _brand() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F0FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Image.asset(
              AppAssets.logo,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.apartment_rounded,
                color: AppColors.deepPurple,
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DHS',
                  style: TextStyle(
                    color: Color(0xFF24305B),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'DIGITAL HOUSING SOCIETY',
                  style: TextStyle(
                    color: AppColors.deepPurple,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, String route) {
    final navigator = Navigator.of(context, rootNavigator: true);

    if (currentRoute == route) {
      if (isDrawer) Navigator.of(context).pop();
      return;
    }

    // Use the stable root navigator. The drawer subtree is disposed as soon
    // as it closes, so navigating with the drawer's BuildContext can fail.
    navigator.pushReplacementNamed(route);
  }

  Future<void> _logout(BuildContext context) async {
    // Keep the drawer route alive while asking for confirmation. Popping the
    // drawer first disposes this context on mobile and previously prevented
    // the logout dialog / navigation from completing.
    final navigator = Navigator.of(context, rootNavigator: true);

    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out of DHS?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await FirebaseAuth.instance.signOut();

    navigator.pushNamedAndRemoveUntil(
      AppConstants.loginRoute,
      (_) => false,
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _DhsNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFF0ECFF) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: selected
                ? const Border(
                    left: BorderSide(
                      color: AppColors.primaryPurple,
                      width: 3,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                destination.icon,
                size: 21,
                color: selected
                    ? AppColors.deepPurple
                    : const Color(0xFF667085),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? AppColors.deepPurple
                        : const Color(0xFF344054),
                    fontWeight:
                        selected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13.5,
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

class _MobileNotificationButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Notifications',
      onPressed: () =>
          Navigator.pushNamed(context, AppConstants.notificationsRoute),
      icon: const Badge(
        smallSize: 7,
        backgroundColor: AppColors.errorRed,
        child: Icon(Icons.notifications_none_rounded),
      ),
    );
  }
}

class _MobileInitialsAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final raw = (user?.displayName ?? user?.email ?? 'Applicant').trim();
    final initials = raw.isEmpty
        ? 'A'
        : raw
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join();

    return CircleAvatar(
      radius: 17,
      backgroundColor: AppColors.deepPurple,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DhsNavDestination {
  const _DhsNavDestination({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}
