import 'package:flutter/material.dart';

/// Centralized color palette defined by the Google Stitch design system for ScanVault.
class AppColors {
  AppColors._();

  // Primary Emerald/Teal Family (Stitch Core: #0D9488)
  static const Color primary = Color(0xFF0D9488);
  static const Color primaryContainer = Color(0xFF0F766E);
  static const Color primaryFixed = Color(0xFF89F5E7);
  static const Color primaryFixedDim = Color(0xFF6BD8CB);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFF4FFFC);
  static const Color onPrimaryFixed = Color(0xFF00201D);
  static const Color onPrimaryFixedVariant = Color(0xFF005049);
  static const Color inversePrimary = Color(0xFF6BD8CB);

  // Secondary Amber Accent Family (Stitch Secondary: #F59E0B)
  static const Color secondary = Color(0xFFF59E0B);
  static const Color secondaryContainer = Color(0xFFFEA619);
  static const Color secondaryFixed = Color(0xFFFFDDB8);
  static const Color secondaryFixedDim = Color(0xFFFFB95F);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF684000);
  static const Color onSecondaryFixed = Color(0xFF2A1700);
  static const Color onSecondaryFixedVariant = Color(0xFF653E00);

  // Tertiary Deep Teal (Stitch Tertiary: #0F766E)
  static const Color tertiary = Color(0xFF0F766E);
  static const Color tertiaryContainer = Color(0xFF115E59);
  static const Color tertiaryFixed = Color(0xFF9CF2E8);
  static const Color tertiaryFixedDim = Color(0xFF80D5CB);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFF3FFFC);
  static const Color onTertiaryFixed = Color(0xFF00201D);
  static const Color onTertiaryFixedVariant = Color(0xFF00504A);

  // Neutral & Typography (Stitch Neutral: #1E293B & #334155)
  static const Color neutral = Color(0xFF1E293B);
  static const Color onSurface = Color(0xFF1E293B);
  static const Color onSurfaceVariant = Color(0xFF334155);
  static const Color outline = Color(0xFF64748B);
  static const Color outlineVariant = Color(0xFFE2E8F0);
  static const Color inverseSurface = Color(0xFF1E293B);
  static const Color inverseOnSurface = Color(0xFFF8F9FA);

  // Surfaces (Stitch Surfaces)
  static const Color surface = Color(0xFFF8F9FA);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFE2E8F0);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF1F3F5);
  static const Color surfaceContainer = Color(0xFFE9ECEF);
  static const Color surfaceContainerHigh = Color(0xFFE2E8F0);
  static const Color surfaceContainerHighest = Color(0xFFCBD5E1);
  static const Color surfaceVariant = Color(0xFFF1F3F5);

  // Error Family
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Dark Mode Surfaces
  static const Color darkSurface = Color(0xFF0F172A);
  static const Color darkSurfaceBright = Color(0xFF1E293B);
  static const Color darkSurfaceContainerLowest = Color(0xFF0B1120);
  static const Color darkSurfaceContainerLow = Color(0xFF131E30);
  static const Color darkSurfaceContainer = Color(0xFF1E293B);
  static const Color darkSurfaceContainerHigh = Color(0xFF334155);
  static const Color darkSurfaceContainerHighest = Color(0xFF475569);
  static const Color darkOnSurface = Color(0xFFF8FAFC);
  static const Color darkOnSurfaceVariant = Color(0xFF94A3B8);
  static const Color darkOutline = Color(0xFF64748B);
  static const Color darkOutlineVariant = Color(0xFF334155);

  // Status & Brand Specific
  static const Color airGappedGlow = Color(0x330D9488);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color darkCardBorder = Color(0xFF334155);
  static const Color pdfRed = Color(0xFFEF4444);
  static const Color imageBlue = Color(0xFF3B82F6);
  static const Color ocrPurple = Color(0xFF8B5CF6);
  static const Color successGreen = Color(0xFF10B981);
}
