import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Convenience extensions used throughout the Chiromo app.

extension StringX on String {
  /// Capitalise the first character.
  String get capitalised =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Convert a snake_case role string to a readable label.
  String get roleLabel => replaceAll('_', ' ').split(' ').map((w) => w.capitalised).join(' ');
}

extension DateTimeX on DateTime {
  /// e.g. "13 Jul 2026"
  String get formattedDate => DateFormat('dd MMM yyyy').format(this);

  /// e.g. "11:25 AM"
  String get formattedTime => DateFormat('hh:mm a').format(this);

  /// e.g. "13 Jul 2026, 11:25 AM"
  String get formattedDateTime => DateFormat('dd MMM yyyy, hh:mm a').format(this);

  /// e.g. "Monday"
  String get dayName => DateFormat('EEEE').format(this);

  /// Whether [this] is the same calendar day as [other].
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}

extension ContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  MediaQueryData get mq => MediaQuery.of(this);
  double get screenWidth => mq.size.width;
  double get screenHeight => mq.size.height;
  bool get isDesktop => screenWidth >= 1200;
  bool get isTablet => screenWidth >= 768 && screenWidth < 1200;
  bool get isMobile => screenWidth < 768;
}

extension NumX on num {
  /// Shorthand for SizedBox(height: this).
  SizedBox get vGap => SizedBox(height: toDouble());
  /// Shorthand for SizedBox(width: this).
  SizedBox get hGap => SizedBox(width: toDouble());
}
