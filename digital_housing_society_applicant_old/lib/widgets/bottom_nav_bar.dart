import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_text_styles.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(Icons.home_rounded, 'Home'),
      _NavItem(Icons.description_rounded, 'Apply'),
      _NavItem(Icons.upload_file_rounded, 'Docs'),
      _NavItem(Icons.payment_rounded, 'Pay'),
      _NavItem(Icons.person_rounded, 'Profile'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 74,
          child: Row(
            children: List.generate(items.length, (index) {
              final active = index == currentIndex;
              final item = items[index];
              return Expanded(
                child: InkWell(
                  onTap: () {
                    final route = AppConstants.bottomNavRoutes[index];
                    final current = ModalRoute.of(context)?.settings.name;
                    if (current != route) Navigator.pushReplacementNamed(context, route);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item.icon, color: active ? AppColors.primaryPurple : AppColors.inactiveGrey),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.captionText.copyWith(
                            color: active ? AppColors.primaryPurple : AppColors.inactiveGrey,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: active ? 5 : 0,
                          height: active ? 5 : 0,
                          decoration: const BoxDecoration(color: AppColors.lavender, shape: BoxShape.circle),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}
