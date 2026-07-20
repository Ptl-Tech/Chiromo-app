import 'package:flutter/material.dart';
import '../../../theme/chiromo_colors.dart';

enum ChiromoButtonVariant { primary, secondary, outline, ghost }

class ChiromoButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final ChiromoButtonVariant variant;
  final bool isFullWidth;

  const ChiromoButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = ChiromoButtonVariant.primary,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final Widget child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    final style = _getStyle(context);

    Widget button;
    switch (variant) {
      case ChiromoButtonVariant.primary:
      case ChiromoButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        );
        break;
      case ChiromoButtonVariant.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        );
        break;
      case ChiromoButtonVariant.ghost:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        );
        break;
    }

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  ButtonStyle? _getStyle(BuildContext context) {
    final theme = Theme.of(context);
    switch (variant) {
      case ChiromoButtonVariant.primary:
        return theme.elevatedButtonTheme.style;
      case ChiromoButtonVariant.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: ChiromoColors.gold,
          foregroundColor: Colors.white,
        );
      case ChiromoButtonVariant.outline:
        return theme.outlinedButtonTheme.style;
      case ChiromoButtonVariant.ghost:
        return theme.textButtonTheme.style;
    }
  }
}
