import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/app_typography.dart';

/// Reusable settings navigation row with leading icon, title, subtitle, and trailing badge/arrow.
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final bool isDestructive;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isDestructive
                ? AppColors.error.withValues(alpha: 0.12)
                : (iconColor != null
                    ? iconColor!.withValues(alpha: 0.12)
                    : (isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerLow)),
            borderRadius: AppDimens.roundedMd,
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDestructive
                ? AppColors.error
                : (iconColor ?? (isDark ? AppColors.primaryFixedDim : AppColors.primary)),
          ),
        ),
        title: Text(
          title,
          style: AppTypography.titleSmall.copyWith(
            color: isDestructive ? AppColors.error : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: trailing ??
            (onTap != null
                ? Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )
                : null),
      ),
    );
  }
}
