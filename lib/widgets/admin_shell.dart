import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../theme/admin_theme.dart';
import 'app_snack.dart';
import 'premium_widgets.dart';

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
  });

  void _openRoute(BuildContext context, String route) {
    final current = ModalRoute.of(context)?.settings.name;
    if (current == route) {
      showAdminSnack(context, '$title is already open');
      return;
    }
    Navigator.pushNamed(context, route);
  }

  void _openBottom(BuildContext context, int index) {
    _openRoute(context, AdminRoutes.bottomRoutes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        titleSpacing: 20,
        title: Text(title),
        actions: [
          LuxuryIconButton(
            icon: Icons.notifications_rounded,
            showBadge: true,
            onTap: () => _openRoute(context, AdminRoutes.notifications),
          ),
          const SizedBox(width: 10),
          PopupMenuButton<String>(
            tooltip: 'Menu',
            color: AdminColors.white,
            elevation: 12,
            shadowColor: AdminColors.primary.withOpacity(0.12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onSelected: (value) {
              if (value == 'profile') _openRoute(context, AdminRoutes.profile);
              if (value == 'notifications') _openRoute(context, AdminRoutes.notifications);
              if (value == 'refresh') showAdminSnack(context, 'Screen refreshed');
              if (value == 'logout') showAdminSnack(context, 'Logout clicked');
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'profile', child: PopupMenuRow(icon: Icons.person_rounded, text: 'Profile')),
              PopupMenuItem(value: 'notifications', child: PopupMenuRow(icon: Icons.notifications_rounded, text: 'Notifications')),
              PopupMenuItem(value: 'refresh', child: PopupMenuRow(icon: Icons.refresh_rounded, text: 'Refresh')),
              PopupMenuItem(value: 'logout', child: PopupMenuRow(icon: Icons.logout_rounded, text: 'Logout')),
            ],
            child: Hero(
              tag: 'admin-profile-hero',
              child: Container(
                margin: const EdgeInsets.only(right: 18),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AdminColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AdminColors.primary.withOpacity(0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  radius: 19,
                  backgroundColor: AdminColors.white,
                  child: Icon(Icons.person_rounded, color: AdminColors.primary),
                ),
              ),
            ),
          ),
        ],
      ),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) => _openBottom(context, index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.people_outline_rounded), selectedIcon: Icon(Icons.people_rounded), label: 'Applicants'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome_rounded), label: 'Balloting'),
          NavigationDestination(icon: Icon(Icons.insert_chart_outlined_rounded), selectedIcon: Icon(Icons.insert_chart_rounded), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
      body: Column(
        children: [
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
              duration: const Duration(milliseconds: 350),
              child: isLoading ? const LoadingState() : body,
            ),
          ),
        ],
      ),
    );
  }
}
