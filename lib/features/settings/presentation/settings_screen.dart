import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/settings_tile.dart';
import '../../../core/widgets/toggle_tile.dart';
import '../domain/settings_controller.dart';
import 'about_screen.dart';

/// Settings & Preferences Screen conforming to Stitch specifications.
class SettingsScreen extends StatefulWidget {
  final SettingsController controller;

  const SettingsScreen({
    super.key,
    required this.controller,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Appearance Theme',
                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.brightness_auto_rounded),
                title: const Text('System Default'),
                trailing: widget.controller.themeMode == ThemeMode.system
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  widget.controller.setThemeMode(ThemeMode.system);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.light_mode_rounded),
                title: const Text('Light Theme'),
                trailing: widget.controller.themeMode == ThemeMode.light
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  widget.controller.setThemeMode(ThemeMode.light);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode_rounded),
                title: const Text('Dark Theme'),
                trailing: widget.controller.themeMode == ThemeMode.dark
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  widget.controller.setThemeMode(ThemeMode.dark);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.margin, vertical: 12),
        children: [
          // Privacy Vault Card Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceContainerLow : const Color(0xFFE6F5F3),
              borderRadius: AppDimens.roundedLg,
              border: Border.all(
                color: isDark ? AppColors.darkCardBorder : AppColors.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '100% Offline & Private',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.primaryFixedDim : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'No cloud subscriptions. Zero telemetry analytics.',
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 1: Scanning & Image Processing
          _buildSectionHeader('SCANNING & CAPTURE'),
          _buildCardContainer([
            ToggleTile(
              icon: Icons.crop_free_rounded,
              title: 'Auto Edge Detection',
              subtitle: 'Automatically detect paper boundaries',
              value: widget.controller.autoCropEnabled,
              onChanged: widget.controller.setAutoCrop,
            ),
            const Divider(),
            SettingsTile(
              icon: Icons.filter_b_and_w_rounded,
              title: 'Default Filter',
              subtitle: 'Magic Color Enhancement',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Default filter set to Magic Color')),
                );
              },
            ),
          ]),
          const SizedBox(height: 20),

          // Section 2: OCR
          _buildSectionHeader('OCR TEXT EXTRACTION'),
          _buildCardContainer([
            SettingsTile(
              icon: Icons.translate_rounded,
              title: 'Recognition Language',
              subtitle: widget.controller.ocrLanguage == 'en' ? 'English (US)' : widget.controller.ocrLanguage,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Multi-language pack ready')),
                );
              },
            ),
          ]),
          const SizedBox(height: 20),

          // Section 3: PDF Quality
          _buildSectionHeader('PDF EXPORT QUALITY'),
          _buildCardContainer([
            SettingsTile(
              icon: Icons.tune_rounded,
              title: 'Compression & Resolution',
              subtitle: 'High (300 DPI Balanced)',
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 20),

          // Section 4: Security
          _buildSectionHeader('APP SECURITY'),
          _buildCardContainer([
            ToggleTile(
              icon: Icons.fingerprint_rounded,
              title: 'App Lock / PIN',
              subtitle: 'Require biometric authentication on launch',
              value: widget.controller.appLockEnabled,
              onChanged: widget.controller.setAppLock,
            ),
          ]),
          const SizedBox(height: 20),

          // Section 5: Appearance
          _buildSectionHeader('APPEARANCE'),
          _buildCardContainer([
            SettingsTile(
              icon: Icons.palette_outlined,
              title: 'Theme',
              subtitle: _getThemeLabel(widget.controller.themeMode),
              onTap: _showThemeSelector,
            ),
          ]),
          const SizedBox(height: 20),

          // Section 6: About
          _buildSectionHeader('ABOUT SCANVAULT'),
          _buildCardContainer([
            SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'About & Open Source',
              subtitle: AppStrings.version,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildCardContainer(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest,
        borderRadius: AppDimens.roundedLg,
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
          width: 1,
        ),
        boxShadow: AppDimens.cardShadow,
      ),
      child: Column(
        children: children,
      ),
    );
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'Dark Theme';
      case ThemeMode.light:
        return 'Light Theme';
      case ThemeMode.system:
        return 'System Default';
    }
  }
}
