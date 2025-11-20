import 'package:flutter/material.dart';

class CaregiverColors {
  // Primary Colors
  static const Color primary = Color(0xFF2563EB); // Modern Blue
  static const Color secondary = Color(0xFF10B981); // Success Green
  static const Color accent = Color(0xFF8B5CF6); // Purple
  
  // Status Colors
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color danger = Color(0xEF4444); // Red
  
  // UI Colors
  static const Color sidebarBg = Color(0xFF1E293B); // Dark Blue Gray
  static const Color sidebarHover = Color(0xFF334155);
  static const Color dark = Color(0xFF1F2937);
  static const Color lightGray = Color(0xFFF3F4F6);
  
  // Status Badge Colors
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return secondary;
      case 'upcoming':
        return primary;
      case 'cancelled':
        return danger;
      default:
        return Colors.grey;
    }
  }
}
