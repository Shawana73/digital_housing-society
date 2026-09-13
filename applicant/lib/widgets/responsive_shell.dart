import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/notification_model.dart';
import '../services/firestore_service.dart';
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
    this.showMobileAppBar = true,
    this.mobileUserName,
  });

  final String currentRoute;
  final Widget child;
  final Color backgroundColor;
  final String mobileTitle;
  final bool showMobileAppBar;
  final String? mobileUserName;

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
        width: (MediaQuery.sizeOf(context).width * 0.86).clamp(275.0, 315.0),
        child: SafeArea(
          child: DhsNavigationPanel(
            currentRoute: currentRoute,
            isDrawer: true,
          ),
        ),
      ),
      appBar: showMobileAppBar
          ? AppBar(
        toolbarHeight: 66,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: AppColors.primaryText,
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(
              Icons.menu_rounded,
              color: AppColors.primaryText,
              size: 26,
            ),
          ),
        ),
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
          _MobileProfileButton(name: mobileUserName),
          const SizedBox(width: 8),
        ],
      )
          : null,
      body: showMobileAppBar ? child : SafeArea(child: child),
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
      child: ClipRect(
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFFCFBFF),
                      Color(0xFFF9F6FF),
                    ],
                    stops: [0.0, 0.60, 1.0],
                  ),
                ),
              ),
            ),
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _SidebarBottomWavePainter(),
                ),
              ),
            ),
            Column(
              children: [
                _brand(),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const tileHeight = 44.0;
                      const horizontalPadding = 14.0;
                      const verticalPadding = 6.0;

                      final totalTileHeight =
                          tileHeight * _destinations.length;
                      final freeSpace = constraints.maxHeight -
                          totalTileHeight -
                          (verticalPadding * 2);

                      final gap = _destinations.length > 1
                          ? (freeSpace / (_destinations.length - 1))
                          .clamp(1.5, 10.0)
                          .toDouble()
                          : 0.0;

                      final fitsWithoutScroll = freeSpace >=
                          gap * (_destinations.length - 1);

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalPadding,
                        ),
                        physics: fitsWithoutScroll
                            ? const NeverScrollableScrollPhysics()
                            : const BouncingScrollPhysics(),
                        itemCount: _destinations.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: gap),
                        itemBuilder: (context, index) {
                          final destination = _destinations[index];
                          return SizedBox(
                            height: tileHeight,
                            child: _buildDestinationTile(
                              context,
                              destination,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE9E2F8),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8FB),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: const Color(0xFFF3DDE9),
                      ),
                    ),
                    child: TextButton.icon(
                      onPressed: () => _logout(context),
                      icon: const Icon(
                        Icons.logout_rounded,
                        size: 20,
                      ),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.errorRed,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 11,
                        ),
                        alignment: Alignment.centerLeft,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 7, 18, 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 31,
                        height: 32,
                        child: CustomPaint(
                          painter: _CommunityMarkPainter(),
                        ),
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Building\nBetter Communities',
                          style: TextStyle(
                            color: AppColors.deepPurple,
                            fontSize: 10.5,
                            height: 1.10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationTile(
      BuildContext context,
      _DhsNavDestination destination,
      ) {
    final selected = currentRoute == destination.route;
    void onTap() => _navigate(context, destination.route);
    if (destination.route != AppConstants.notificationsRoute) {
      return _NavTile(
        destination: destination,
        selected: selected,
        onTap: onTap,
      );
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return _NavTile(
        destination: destination,
        selected: selected,
        onTap: onTap,
      );
    }

    final service = FirestoreService();

    return StreamBuilder(
      stream: service.getNotifications(uid),
      builder: (context, snapshot) {
        var hasUnread = false;

        if (snapshot.hasData) {
          hasUnread = snapshot.data!.docs
              .map(NotificationModel.fromFirestore)
              .any((notification) => !notification.isRead);
        }

        return _NavTile(
          destination: destination,
          selected: selected,
          onTap: onTap,
          showIndicator: hasUnread,
        );
      },
    );
  }

  Widget _brand() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 8, 6),
        decoration: BoxDecoration(
          color: const Color(0xF7FFFFFF),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x127B55E7),
              blurRadius: 20,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F1FF),
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
      ),
    );
  }

  void _navigate(BuildContext context, String route) {
    final navigator = Navigator.of(context, rootNavigator: true);

    if (currentRoute == route) {
      if (isDrawer) Navigator.of(context).pop();
      return;
    }

    navigator.pushReplacementNamed(route);
  }

  Future<void> _logout(BuildContext context) async {
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
    this.showIndicator = false,
  });

  final _DhsNavDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final bool showIndicator;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: selected
                ? const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF6537F3),
                Color(0xFF8744FF),
              ],
            )
                : null,
            boxShadow: selected
                ? const [
              BoxShadow(
                color: Color(0x386B3EF5),
                blurRadius: 17,
                offset: Offset(0, 7),
              ),
            ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                destination.icon,
                size: 20,
                color: selected
                    ? Colors.white
                    : const Color(0xFF26345F),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        destination.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF26345F),
                          fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (showIndicator) ...[
                      const SizedBox(width: 8),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFFFF4567),
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox(
                          width: 8,
                          height: 8,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Colors.white,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarBottomWavePainter extends CustomPainter {
  const _SidebarBottomWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final topWave = Paint()
      ..color = const Color(0xFFF0E8FF)
      ..style = PaintingStyle.fill;

    final topPath = Path()
      ..moveTo(0, size.height - 138)
      ..cubicTo(
        size.width * 0.20,
        size.height - 154,
        size.width * 0.44,
        size.height - 128,
        size.width * 0.62,
        size.height - 143,
      )
      ..cubicTo(
        size.width * 0.80,
        size.height - 158,
        size.width * 0.92,
        size.height - 139,
        size.width,
        size.height - 145,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(topPath, topWave);

    final middleWave = Paint()
      ..color = const Color(0xFFDCCEFF)
      ..style = PaintingStyle.fill;

    final middlePath = Path()
      ..moveTo(0, size.height - 70)
      ..cubicTo(
        size.width * 0.18,
        size.height - 112,
        size.width * 0.38,
        size.height - 106,
        size.width * 0.52,
        size.height - 70,
      )
      ..cubicTo(
        size.width * 0.68,
        size.height - 28,
        size.width * 0.81,
        size.height - 106,
        size.width,
        size.height - 88,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(middlePath, middleWave);

    final lowerWave = Paint()
      ..color = const Color(0xFFCDB9FF)
      ..style = PaintingStyle.fill;

    final lowerPath = Path()
      ..moveTo(0, size.height - 8)
      ..cubicTo(
        size.width * 0.22,
        size.height - 72,
        size.width * 0.50,
        size.height - 20,
        size.width * 0.70,
        size.height - 52,
      )
      ..cubicTo(
        size.width * 0.84,
        size.height - 70,
        size.width * 0.92,
        size.height - 40,
        size.width,
        size.height - 55,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(lowerPath, lowerWave);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CommunityMarkPainter extends CustomPainter {
  const _CommunityMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.deepPurple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final stem = Path()
      ..moveTo(size.width * 0.50, size.height * 0.90)
      ..cubicTo(
        size.width * 0.48,
        size.height * 0.68,
        size.width * 0.47,
        size.height * 0.52,
        size.width * 0.40,
        size.height * 0.38,
      );
    canvas.drawPath(stem, paint);

    final rightStem = Path()
      ..moveTo(size.width * 0.50, size.height * 0.90)
      ..cubicTo(
        size.width * 0.53,
        size.height * 0.67,
        size.width * 0.60,
        size.height * 0.48,
        size.width * 0.72,
        size.height * 0.31,
      );
    canvas.drawPath(rightStem, paint);

    final leftLeaf = Path()
      ..moveTo(size.width * 0.40, size.height * 0.41)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.39,
        size.width * 0.12,
        size.height * 0.24,
        size.width * 0.19,
        size.height * 0.16,
      )
      ..cubicTo(
        size.width * 0.33,
        size.height * 0.17,
        size.width * 0.43,
        size.height * 0.24,
        size.width * 0.40,
        size.height * 0.41,
      );
    canvas.drawPath(leftLeaf, paint);

    final rightLeaf = Path()
      ..moveTo(size.width * 0.68, size.height * 0.34)
      ..cubicTo(
        size.width * 0.69,
        size.height * 0.14,
        size.width * 0.82,
        size.height * 0.08,
        size.width * 0.91,
        size.height * 0.10,
      )
      ..cubicTo(
        size.width * 0.91,
        size.height * 0.24,
        size.width * 0.83,
        size.height * 0.35,
        size.width * 0.68,
        size.height * 0.34,
      );
    canvas.drawPath(rightLeaf, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MobileNotificationButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return IconButton(
        tooltip: 'Notifications',
        onPressed: () =>
            Navigator.pushNamed(context, AppConstants.notificationsRoute),
        icon: const Icon(
          Icons.notifications_none_rounded,
          color: AppColors.primaryText,
          size: 26,
        ),
      );
    }

    final service = FirestoreService();

    return StreamBuilder(
      stream: service.getNotifications(uid),
      builder: (context, snapshot) {
        var hasUnread = false;

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          hasUnread = docs
              .map(NotificationModel.fromFirestore)
              .any((notification) => !notification.isRead);
        }

        return IconButton(
          tooltip: 'Notifications',
          onPressed: () =>
              Navigator.pushNamed(context, AppConstants.notificationsRoute),
          icon: Badge(
            isLabelVisible: hasUnread,
            smallSize: 7,
            backgroundColor: AppColors.errorRed,
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.primaryText,
              size: 26,
            ),
          ),
        );
      },
    );
  }
}

class _MobileProfileButton extends StatelessWidget {
  const _MobileProfileButton({this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final providedName = name?.trim() ?? '';
    final fallbackName =
    (user?.displayName ?? user?.email?.split('@').first ?? 'Applicant')
        .trim();

    final displayName =
    providedName.isNotEmpty ? providedName : fallbackName;

    final parts = displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    final initials = parts.isEmpty
        ? 'A'
        : parts
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            Navigator.pushNamed(context, AppConstants.profileRoute),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 3,
            vertical: 3,
          ),
          child: CircleAvatar(
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
          ),
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
