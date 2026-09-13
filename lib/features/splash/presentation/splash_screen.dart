import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/widgets/scanvault_logo.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../main_shell/presentation/main_shell_screen.dart';

/// Stitch-faithful Animated Splash Screen for ScanVault.
class SplashScreen extends StatefulWidget {
  final PreferencesService preferencesService;

  const SplashScreen({
    super.key,
    required this.preferencesService,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  double _progress = 0.28;
  String _statusText = 'Initializing on-device sandbox • 100% Private';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _runInitializationSequence();
  }

  void _runInitializationSequence() {
    final steps = [
      {'progress': 0.54, 'text': 'Verifying local storage sandbox • Secure'},
      {'progress': 0.82, 'text': 'Mounting offline vault • Zero Telemetry'},
      {'progress': 1.0, 'text': 'Vault ready • Launching Workspace'},
    ];

    var stepIndex = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (!mounted) return;

      if (stepIndex < steps.length) {
        setState(() {
          _progress = steps[stepIndex]['progress'] as double;
          _statusText = steps[stepIndex]['text'] as String;
        });
        stepIndex++;
      } else {
        timer.cancel();
        _navigateToNextScreen();
      }
    });
  }

  void _navigateToNextScreen() {
    final isFirstLaunch = widget.preferencesService.isFirstLaunch;
    final nextScreen = isFirstLaunch
        ? OnboardingScreen(preferencesService: widget.preferencesService)
        : MainShellScreen(preferencesService: widget.preferencesService);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Ambient Security Glow Backdrops
          Positioned(
            top: -50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.margin, vertical: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top System Verification Badge
                  _buildAirGappedBadge(isDark),

                  // Center Stage: Hero Identity
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ScanVaultLogo(size: 76, showText: false),
                      const SizedBox(height: 24),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Scan',
                              style: AppTypography.displayLargeMobile.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: 'Vault',
                              style: AppTypography.displayLargeMobile.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.appTagline,
                        style: AppTypography.titleSmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      // Privacy Credential Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerLow,
                          borderRadius: AppDimens.roundedFull,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.security_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Local On-Device Storage • Zero Cloud',
                              style: AppTypography.labelMedium.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Bottom Stage: Progress track & Footer
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Smooth Linear Track
                      Container(
                        width: 200,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: AnimatedFractionallySizedBox(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.centerLeft,
                          widthFactor: _progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.primaryFixedDim : AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isDark ? AppColors.primaryFixedDim : AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _statusText,
                            style: AppTypography.bodySmall.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '100% Offline • ${AppStrings.version}',
                        style: AppTypography.labelSmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAirGappedBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainerLow : Colors.white,
        borderRadius: AppDimens.roundedFull,
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
          width: 0.8,
        ),
        boxShadow: AppDimens.cardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            AppStrings.airGapped.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
