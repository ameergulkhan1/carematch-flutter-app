import 'package:flutter/material.dart';

class ClientColors {
  // Primary Brand Colors - Modern & Professional
  static const Color primary = Color(0xFF4F46E5); // Vibrant Indigo
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color secondary = Color(0xFF06B6D4); // Cyan
  static const Color accent = Color(0xFF8B5CF6); // Purple
  static const Color accentOrange = Color(0xFFF97316); // Vibrant Orange

  // Status Colors - Clear & Accessible
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color warning = Color(0xFFFBBF24); // Amber
  static const Color danger = Color(0xFFEF4444); // Red
  static const Color info = Color(0xFF3B82F6); // Blue

  // Background Colors - Clean & Modern
  static const Color background = Color(0xFFF9FAFB); // Light Gray
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color surfaceLight = Color(0xFFF3F4F6);
  static const Color border = Color(0xFFE5E7EB);

  // Sidebar Colors - Professional Dark Theme
  static const Color sidebarBg = Color(0xFF1F2937); // Dark Gray
  static const Color sidebarHover = Color(0xFF374151);
  static const Color sidebarActive = Color(0xFF4F46E5);
  static const Color sidebarText = Color(0xFFD1D5DB);
  static const Color sidebarTextActive = Color(0xFFFFFFFF);

  // Text Colors - Hierarchy
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color dark = Color(0xFF1F2937);

  // Gradients - Modern & Eye-catching
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF9FAFB)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Shadows - Depth & Elevation
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      offset: const Offset(0, 1),
      blurRadius: 3,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      offset: const Offset(0, 2),
      blurRadius: 8,
    ),
  ];

  static List<BoxShadow> cardHoverShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      offset: const Offset(0, 4),
      blurRadius: 16,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      offset: const Offset(0, 2),
      blurRadius: 8,
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: primary.withOpacity(0.3),
      offset: const Offset(0, 4),
      blurRadius: 12,
    ),
  ];
}
