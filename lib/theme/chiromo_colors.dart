import 'package:flutter/material.dart';

/// Chiromo Hospital Group brand color palette.
/// Extracted from the official Chiromo Hospital Group logo:
///   - Navy blue lotus + wordmark
///   - Gold/amber dome arch
///   - Crimson tagline "Recovery In Dignity"
class ChiromoColors {
  ChiromoColors._();

  // ── Primary – Vibrant Emerald & Teal ──────────────────────────
  static const Color primaryDarkest = Color(0xFF003D33);
  static const Color primaryDark = Color(0xFF00796B);
  static const Color primary = Color(0xFF00C896); // Shiny Emerald Green
  static const Color primaryLight = Color(0xFF52DE97); // Neon Mint
  static const Color primaryLighter = Color(0xFFB9F6CA);
  static const Color primarySurface = Color(0xFFE8FDF5);

  // ── Secondary – Vibrant Gold/Amber ────────────────────────────
  static const Color gold = Color(0xFFFFC107); // Shiny Gold
  static const Color goldLight = Color(0xFFFFD54F);
  static const Color goldDark = Color(0xFFFF8F00);
  static const Color goldSurface = Color(0xFFFFF8E1);

  // ── Accent – Electric Pink/Crimson ────────────────────────────
  static const Color crimson = Color(0xFFFF4081); // Electric Pink
  static const Color crimsonLight = Color(0xFFFF80AB);
  static const Color accent = Color(0xFFFF4081);
  static const Color accentLight = Color(0xFFFF80AB);
  static const Color crimsonSurface = Color(0xFFFCE4EC);

  // ── Semantic ──────────────────────────────────────────────────
  static const Color success = Color(0xFF00E676);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFFF9100);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFFF1744);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF00B0FF);
  static const Color infoLight = Color(0xFFE1F5FE);

  // ── Neutrals (Light Mode) ─────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF4F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEBF1F6);
  static const Color border = Color(0xFFD1DDE8);
  static const Color divider = Color(0xFFE0E5EC);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Neutrals (Dark Mode) ──────────────────────────────────────
  static const Color darkBackground = Color(0xFF0B1120);
  static const Color darkSurface = Color(0xFF152033);
  static const Color darkSurfaceVariant = Color(0xFF1E2D45);
  static const Color darkBorder = Color(0xFF2D3F57);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // ── Gradients & Glassmorphism ─────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [goldLight, gold, goldDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [primaryDark, primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradientBlue = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF00B0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradientGold = LinearGradient(
    colors: [Color(0xFFFFD54F), Color(0xFFFF9100)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Appointment Status Colors ─────────────────────────────────
  static const Color statusPending = Color(0xFFFF9100);
  static const Color statusConfirmed = Color(0xFF00B0FF);
  static const Color statusCheckedIn = Color(0xFF00E5FF);
  static const Color statusInConsultation = Color(0xFFFF4081);
  static const Color statusCompleted = Color(0xFF00E676);
  static const Color statusCancelled = Color(0xFFFF1744);
  static const Color statusNoShow = Color(0xFF94A3B8);
}
