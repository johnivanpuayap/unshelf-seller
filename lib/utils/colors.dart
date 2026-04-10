import 'package:flutter/material.dart';

/// Unshelf Seller brand colors and semantic tokens.
///
/// Use these for brand-specific needs. For most UI elements,
/// prefer [Theme.of(context).colorScheme] which derives from these.
class AppColors {
  AppColors._();

  // ─── Brand palette ───
  static const Color primaryColor = Color(0xFF0AB68D);
  static const Color darkColor = Color(0xFF028174);
  static const Color lightColor = Color(0xFFE0F5EE);

  // ─── Semantic colors ───
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFD9534F);
  static const Color info = Color(0xFF1976D2);

  // ─── Neutral palette ───
  static const Color textPrimary = Color(0xFF1C1B1F);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color border = Color(0xFFE0E0E0);
  static const Color surface = Color(0xFFF5F5F5);
  static const Color background = Color(0xFFF8F9FA);

  // ─── Status badge colors ───
  static const Color statusPending = Color(0xFFFFF3E0);
  static const Color statusPendingText = Color(0xFFE65100);
  static const Color statusProcessing = Color(0xFFE3F2FD);
  static const Color statusProcessingText = Color(0xFF1565C0);
  static const Color statusReady = Color(0xFFE8F5E9);
  static const Color statusReadyText = Color(0xFF2E7D32);
  static const Color statusCompleted = Color(0xFFE0F2F1);
  static const Color statusCompletedText = Color(0xFF00695C);
  static const Color statusCancelled = Color(0xFFFFEBEE);
  static const Color statusCancelledText = Color(0xFFC62828);
}
