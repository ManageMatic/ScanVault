import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/toggle_tile.dart';
import '../domain/settings_controller.dart';
import 'about_screen.dart';

import '../../auth/domain/auth_controller.dart';

/// Settings & Privacy Security screen conforming strictly to Stitch design specs.
class SettingsScreen extends StatefulWidget {
  final SettingsController controller;
  final AuthController? authController;
  final VoidCallback? onOpenAccount;

  const SettingsScreen({
    super.key,
    required this.controller,
    this.authController,
    this.onOpenAccount,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onStateChanged);
    _searchController.dispose();
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SCANVAULT',
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.primary,
              ),
            ),
            Text(
              'Settings',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.margin, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Privacy Trust Hero Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
                  width: 1,
                ),
                boxShadow: AppDimens.cardShadow,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              '100% Private & Offline',
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceContainerHigh : AppColors.tertiaryFixed,
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Text(
                                'Air-Gapped',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isDark ? AppColors.primaryFixedDim : AppColors.onTertiaryFixed,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No accounts, no trackers, zero remote servers. All OCR and PDF operations execute strictly on local device silicon.',
                          style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 14),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Zero Cloud Footprint • Encrypted Vault',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Search Settings Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search security parameters, OCR...',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // SECTION 0: ACCOUNT & USER IDENTITY
            _buildSectionHeader(
              icon: Icons.account_circle_rounded,
              title: 'ACCOUNT & USER PROFILE',
            ),
            _buildCardGroup([
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.authController?.isAuthenticated == true
                        ? AppColors.primaryContainer.withValues(alpha: 0.15)
                        : (isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerHigh),
                    shape: BoxShape.circle,
                  ),
                  child: widget.authController?.currentUser?.avatarUrl != null &&
                          widget.authController!.currentUser!.avatarUrl!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            widget.authController!.currentUser!.avatarUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : Icon(
                          widget.authController?.isAuthenticated == true
                              ? Icons.person_rounded
                              : Icons.person_outline_rounded,
                          color: widget.authController?.isAuthenticated == true
                              ? AppColors.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                ),
                title: Text(
                  widget.authController?.isAuthenticated == true
                      ? (widget.authController?.currentUser?.name ?? widget.authController?.currentUser?.email ?? 'User')
                      : 'Offline Guest Vault',
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  widget.authController?.isAuthenticated == true
                      ? widget.authController!.currentUser!.email
                      : 'Sandboxed local storage • Sign in to sync',
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: FilledButton.tonal(
                  onPressed: widget.onOpenAccount,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    widget.authController?.isAuthenticated == true ? 'Manage' : 'Sign In',
                    style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 18),

            // SECTION 1: SECURITY & ACCESS
            _buildSectionHeader(
              icon: Icons.shield_rounded,
              title: 'SECURITY & ACCESS',
            ),
            _buildCardGroup([
              ToggleTile(
                icon: Icons.lock_clock_rounded,
                title: 'App Lock',
                subtitle: 'Require authentication on launch',
                value: widget.controller.appLockEnabled,
                onChanged: widget.controller.setAppLock,
              ),
              const Divider(height: 1),
              ToggleTile(
                icon: Icons.fingerprint_rounded,
                title: 'Biometric Unlock',
                subtitle: 'Face ID & Touch ID hardware pass',
                value: widget.controller.biometricEnabled,
                onChanged: widget.controller.setBiometric,
              ),
              const Divider(height: 1),
              _buildClickableTile(
                icon: Icons.pin_rounded,
                title: 'Change 6-Digit PIN',
                subtitle: 'Last updated 30 days ago',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN modification modal ready')),
                  );
                },
              ),
              const Divider(height: 1),
              _buildValueTile(
                icon: Icons.timer_outlined,
                title: 'Auto-Lock Duration',
                subtitle: 'Suspension trigger interval',
                badgeText: 'Immediate',
              ),
              const Divider(height: 1),
              ToggleTile(
                icon: Icons.fmd_bad_rounded,
                iconColor: AppColors.error,
                title: 'Brute-Force Vault Destruction',
                subtitle: 'Wipe database after 10 failed attempts',
                value: widget.controller.bruteForceEnabled,
                onChanged: widget.controller.setBruteForce,
              ),
            ]),
            const SizedBox(height: 18),

            // SECTION 2: SCANNING & CAMERA PREFERENCES
            _buildSectionHeader(
              icon: Icons.center_focus_strong_rounded,
              title: 'SCANNING & CAMERA PREFERENCES',
            ),
            _buildCardGroup([
              ToggleTile(
                icon: Icons.crop_free_rounded,
                title: 'Auto-Edge Detection',
                subtitle: 'Real-time perspective quadrilateral snap',
                value: widget.controller.autoCropEnabled,
                onChanged: widget.controller.setAutoCrop,
              ),
              const Divider(height: 1),
              _buildActionTileWithBadge(
                icon: Icons.tune_rounded,
                title: 'Default Filter',
                subtitle: 'Applied immediately upon capture',
                badgeText: widget.controller.defaultFilter,
                badgeColor: isDark ? AppColors.darkSurfaceContainerHigh : AppColors.primaryFixed,
                badgeTextColor: isDark ? AppColors.primaryFixedDim : AppColors.onPrimaryFixed,
                onTap: () {
                  widget.controller.setDefaultFilter(
                    widget.controller.defaultFilter == 'Document Clean' ? 'Magic Color' : 'Document Clean',
                  );
                },
              ),
              const Divider(height: 1),
              ToggleTile(
                icon: Icons.volume_off_rounded,
                title: 'Camera Sound',
                subtitle: 'Shutter feedback chime',
                value: widget.controller.cameraSoundEnabled,
                onChanged: widget.controller.setCameraSound,
              ),
              const Divider(height: 1),
              ToggleTile(
                icon: Icons.screen_rotation_rounded,
                title: 'Gyroscope Horizon Guide',
                subtitle: 'Sensory level line for flat document alignment',
                value: widget.controller.gyroscopeGuideEnabled,
                onChanged: widget.controller.setGyroscopeGuide,
              ),
              const Divider(height: 1),
              _buildValueTile(
                icon: Icons.flash_on_rounded,
                title: 'Flash Mode',
                subtitle: 'Default torch posture',
                badgeText: widget.controller.flashMode,
              ),
            ]),
            const SizedBox(height: 18),

            // SECTION 3: OCR & LOCAL INTELLIGENCE
            _buildSectionHeader(
              icon: Icons.psychology_rounded,
              title: 'OCR & INTELLIGENCE',
            ),
            _buildCardGroup([
              _buildClickableTile(
                icon: Icons.translate_rounded,
                title: 'Default OCR Language',
                subtitle: widget.controller.ocrLanguage,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Multi-language offline pack active')),
                  );
                },
              ),
              const Divider(height: 1),
              ToggleTile(
                icon: Icons.document_scanner_rounded,
                title: 'Auto-OCR Scans',
                subtitle: 'Recognize text immediately after capture',
                value: widget.controller.autoOcrEnabled,
                onChanged: widget.controller.setAutoOcr,
              ),
              const Divider(height: 1),
              _buildValueTile(
                icon: Icons.memory_rounded,
                title: 'On-Device Neural Model',
                subtitle: 'v2.4 Core ML Engine (Offline)',
                badgeText: 'Active',
              ),
            ]),
            const SizedBox(height: 18),

            // SECTION 4: STORAGE & CACHE
            _buildSectionHeader(
              icon: Icons.pie_chart_outline_rounded,
              title: 'STORAGE & CACHE',
              trailingText: '1.24 GB Used',
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
                  width: 1,
                ),
                boxShadow: AppDimens.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Visualizer bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9999),
                    child: SizedBox(
                      height: 10,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 79,
                            child: Container(color: AppColors.primary),
                          ),
                          Expanded(
                            flex: 11,
                            child: Container(color: AppColors.secondaryContainer),
                          ),
                          Expanded(
                            flex: 10,
                            child: Container(color: isDark ? AppColors.darkSurfaceContainerHigh : const Color(0xFFBCC9C6)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Responsive Legends
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    alignment: WrapAlignment.start,
                    children: [
                      _buildStorageLegend('Docs', '980 MB', AppColors.primary),
                      _buildStorageLegend('Thumbs', '140 MB', AppColors.secondaryContainer),
                      _buildStorageLegend('Cache', '120 MB', isDark ? AppColors.darkSurfaceContainerHigh : const Color(0xFFBCC9C6)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Actions
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cache cleaned • 120 MB freed')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(
                          color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
                        ),
                      ),
                      icon: const Icon(Icons.cleaning_services_rounded, size: 18),
                      label: Text(
                        'Clear Cache & Temp Files (120 MB)',
                        style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Exporting Encrypted Vault Archive...')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: AppColors.onPrimaryContainer,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.cloud_download_rounded, size: 18),
                      label: Text(
                        'Export Entire Vault Backup',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // SECTION 5: APPEARANCE & THEME
            _buildSectionHeader(
              icon: Icons.palette_outlined,
              title: 'APPEARANCE & THEME',
            ),
            _buildCardGroup([
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: _showThemeSelector,
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.palette_rounded, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'App Theme',
                                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  _getThemeLabel(widget.controller.themeMode),
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.unfold_more_rounded, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // 3-way Theme Selection Segmented Switcher
                    Row(
                      children: [
                        _buildThemeOption(
                          context,
                          mode: ThemeMode.system,
                          label: 'System',
                          icon: Icons.brightness_auto_rounded,
                          isSelected: widget.controller.themeMode == ThemeMode.system,
                        ),
                        const SizedBox(width: 8),
                        _buildThemeOption(
                          context,
                          mode: ThemeMode.light,
                          label: 'Light',
                          icon: Icons.light_mode_rounded,
                          isSelected: widget.controller.themeMode == ThemeMode.light,
                        ),
                        const SizedBox(width: 8),
                        _buildThemeOption(
                          context,
                          mode: ThemeMode.dark,
                          label: 'Dark',
                          icon: Icons.dark_mode_rounded,
                          isSelected: widget.controller.themeMode == ThemeMode.dark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 18),

            // SECTION 6: ABOUT SCANVAULT
            _buildSectionHeader(
              icon: Icons.info_outline_rounded,
              title: 'ABOUT SCANVAULT',
            ),
            _buildCardGroup([
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.token_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ScanVault v3.2.0 (Build 412)',
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Open Source (GPL-3.0) • No trackers',
                            style: AppTypography.bodySmall.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '100% Free for life • Zero paywalls',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _buildClickableTile(
                icon: Icons.code_rounded,
                title: 'Third-Party & Open Source Licenses',
                subtitle: 'View Apache 2.0, MIT, and BSD notices',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const AboutScreen()),
                  );
                },
              ),
              const Divider(height: 1),
              _buildClickableTile(
                icon: Icons.terminal_rounded,
                title: 'GitHub Source Repository',
                subtitle: 'ManageMatic/ScanVault on GitHub',
                trailingIcon: Icons.open_in_new_rounded,
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 20),

            // Footnote
            Center(
              child: Text(
                'ScanVault encrypts every byte at rest using local sandboxed storage.',
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    String? trailingText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (trailingText != null)
            Text(
              trailingText,
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
          width: 1,
        ),
        boxShadow: AppDimens.cardShadow,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildClickableTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    IconData trailingIcon = Icons.chevron_right_rounded,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurfaceContainerLow
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      title: Text(
        title,
        style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(trailingIcon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }

  Widget _buildValueTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      title: Text(
        title,
        style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(
          badgeText,
          style: AppTypography.labelSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildActionTileWithBadge({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      title: Text(
        title,
        style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                badgeText,
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: badgeTextColor,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.expand_more_rounded, size: 16, color: badgeTextColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStorageLegend(String label, String size, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ',
          style: AppTypography.labelSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          '($size)',
          style: AppTypography.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
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

  Widget _buildThemeOption(
    BuildContext context, {
    required ThemeMode mode,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isSelected
        ? (isDark ? AppColors.primary : AppColors.primary)
        : (isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow);

    final fgColor = isSelected
        ? Colors.white
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.controller.setThemeMode(mode),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.transparent : (isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: fgColor),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: fgColor,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
