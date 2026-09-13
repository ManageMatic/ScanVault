import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import 'scanner_icon.dart';

/// Navigation bar item descriptor.
class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Custom Stitch-styled Bottom Navigation Bar for ScanVault
/// with the center scanner button elevated above the nav bar.
class ScanVaultBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onScanPressed;

  const ScanVaultBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onScanPressed,
  });

  static const List<NavItem> items = [
    NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    NavItem(
      icon: Icons.folder_outlined,
      activeIcon: Icons.folder_rounded,
      label: 'Docs',
    ),
    NavItem(
      icon: Icons.document_scanner_outlined,
      activeIcon: Icons.document_scanner_rounded,
      label: 'Scan',
    ),
    NavItem(
      icon: Icons.construction_outlined,
      activeIcon: Icons.construction_rounded,
      label: 'Tools',
    ),
    NavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurfaceContainerLowest : Colors.white;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.cardBorder;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Main Navigation Bar Container
        Container(
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              top: BorderSide(color: borderColor, width: 0.8),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 10,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 60,
              child: Row(
                children: [
                  _buildNavItem(context, 0),
                  _buildNavItem(context, 1),
                  // Reserved middle gap for the elevated center button
                  const Expanded(child: SizedBox()),
                  _buildNavItem(context, 3),
                  _buildNavItem(context, 4),
                ],
              ),
            ),
          ),
        ),

        // Elevated Floating Center Scanner Button (protruding above top edge)
        Positioned(
          top: -14,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onScanPressed,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF00685F),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00685F).withValues(alpha: 0.38),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const StitchScannerIcon(
                  size: 27,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(BuildContext context, int index) {
    final item = items[index];
    final isSelected = currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeColor = isDark ? AppColors.primaryFixedDim : const Color(0xFF00685F);
    final inactiveColor = isDark
        ? AppColors.darkOnSurfaceVariant.withValues(alpha: 0.7)
        : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.75);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: 24,
                  color: isSelected ? activeColor : inactiveColor,
                ),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected ? activeColor : inactiveColor,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
