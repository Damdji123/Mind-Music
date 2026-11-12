import 'package:flutter/material.dart';

/// Spacing, corner radii, and dimensional tokens from DESIGN.md.
class AppDimensions {
  AppDimensions._();

  // Spacing & Margins
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 14.0;
  static const double gutter = 16.0;
  static const double spaceLg = 20.0;
  static const double spaceXl = 32.0;
  static const double margin = 20.0; // Outer canvas padding

  // Floating Island Bottom Clearance (space-xl + 64px dock)
  static const double bottomNavClearance = 96.0;

  // Corner Radii
  static const double radiusSm = 8.0;
  static const double radiusDefault = 16.0;
  static const double radiusMd = 24.0;
  static const double radiusLg = 32.0;
  static const double radiusXl = 48.0;
  static const double radiusFull = 9999.0;

  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderDefault = BorderRadius.all(Radius.circular(radiusDefault));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius borderFull = BorderRadius.all(Radius.circular(radiusFull));

  // Glass Blur Tokens
  static const double blurAmbient = 20.0;
  static const double blurDefault = 24.0;
  static const double blurFloating = 28.0;
  static const double blurModal = 36.0;
  static const double blurIntense = 40.0;
}
