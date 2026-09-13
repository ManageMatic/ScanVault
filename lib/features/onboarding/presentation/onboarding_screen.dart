import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/widgets/primary_button.dart';
import '../../main_shell/presentation/main_shell_screen.dart';

class OnboardingItem {
  final IconData icon;
  final String badgeText;
  final String title;
  final String description;
  final Color accentColor;

  const OnboardingItem({
    required this.icon,
    required this.badgeText,
    required this.title,
    required this.description,
    required this.accentColor,
  });
}

/// Stitch-styled Onboarding Carousel screen.
class OnboardingScreen extends StatefulWidget {
  final PreferencesService preferencesService;

  const OnboardingScreen({
    super.key,
    required this.preferencesService,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = const [
    OnboardingItem(
      icon: Icons.shield_rounded,
      badgeText: 'AIR-GAPPED & PRIVACY FIRST',
      title: AppStrings.onboardingTitle1,
      description: AppStrings.onboardingDesc1,
      accentColor: AppColors.primary,
    ),
    OnboardingItem(
      icon: Icons.document_scanner_rounded,
      badgeText: 'INTELLIGENT EDGE DETECTION',
      title: AppStrings.onboardingTitle2,
      description: AppStrings.onboardingDesc2,
      accentColor: Color(0xFF008378),
    ),
    OnboardingItem(
      icon: Icons.picture_as_pdf_rounded,
      badgeText: 'COMPLETE LOCAL UTILITIES',
      title: AppStrings.onboardingTitle3,
      description: AppStrings.onboardingDesc3,
      accentColor: AppColors.secondary,
    ),
  ];

  Future<void> _completeOnboarding() async {
    await widget.preferencesService.setFirstLaunchCompleted();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MainShellScreen(preferencesService: widget.preferencesService),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerLow,
                      borderRadius: AppDimens.roundedFull,
                    ),
                    child: Text(
                      'Step ${_currentPage + 1} of ${_items.length}',
                      style: AppTypography.labelSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      AppStrings.skip,
                      style: AppTypography.labelMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Carousel Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Hero Icon with Multi-layer Glow
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceContainerHigh
                                : item.accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkCardBorder
                                  : item.accentColor.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            item.icon,
                            size: 64,
                            color: isDark ? AppColors.primaryFixedDim : item.accentColor,
                          ),
                        ),
                        const SizedBox(height: 36),
                        // Badge Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                            borderRadius: AppDimens.roundedFull,
                          ),
                          child: Text(
                            item.badgeText,
                            style: AppTypography.labelSmall.copyWith(
                              color: isDark ? AppColors.primaryFixedDim : AppColors.primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item.title,
                          style: AppTypography.headlineMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.description,
                          style: AppTypography.bodyMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Actions & Dots
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Smooth Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_items.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        width: isActive ? 24 : 6,
                        decoration: BoxDecoration(
                          color: isActive
                              ? (isDark ? AppColors.primaryFixedDim : AppColors.primary)
                              : (isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  // Next / Get Started Button
                  PrimaryButton(
                    label: _currentPage == _items.length - 1
                        ? AppStrings.getStarted
                        : AppStrings.next,
                    onPressed: _nextPage,
                    icon: _currentPage == _items.length - 1
                        ? Icons.arrow_forward_rounded
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
