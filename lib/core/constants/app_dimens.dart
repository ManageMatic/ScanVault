import 'package:flutter/material.dart';

/// Centralized dimensions and radius definitions based on Stitch design specs.
class AppDimens {
  AppDimens._();

  // Spacing
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;

  static const double margin = 16.0;
  static const double marginTablet = 32.0;
  static const double gutter = 16.0;
  static const double gutterTablet = 24.0;

  // Border Radii
  static const double radiusSm = 4.0;
  static const double radiusDefault = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 9999.0;

  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius roundedDefault = BorderRadius.all(Radius.circular(radiusDefault));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius roundedXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(radiusFull));

  // Elevations & Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x050F172A),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x0F0F172A),
      blurRadius: 6,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> fabShadow = [
    BoxShadow(
      color: Color(0x3300685F),
      blurRadius: 15,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x140F172A),
      blurRadius: 6,
      offset: Offset(0, 4),
    ),
  ];

  // Component Sizes
  static const double fabSize = 56.0;
  static const double bottomNavHeight = 72.0;
  static const double touchTargetMin = 48.0;
  static const double buttonHeight = 48.0;
}
