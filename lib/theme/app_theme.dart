import 'package:flutter/material.dart';

/// Pink Flamingo brand palette and theme.
class AppColors {
  AppColors._();

  /// Soft header pink (top bar background).
  static const Color pink = Color(0xFFFF8FCB);

  /// Lighter pink used for gradients / search fields on the header.
  static const Color pinkLight = Color(0xFFFFB6DD);

  /// Hot magenta — logo, active states, prices.
  static const Color magenta = Color(0xFFFF2D95);

  /// App background.
  static const Color background = Color(0xFFF7F7F8);

  static const Color card = Colors.white;
  static const Color textDark = Color(0xFF1C1C1E);
  static const Color textGrey = Color(0xFF8A8A8E);
  static const Color divider = Color(0xFFEDEDED);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.magenta,
        primary: AppColors.magenta,
        surface: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      splashColor: AppColors.pinkLight.withValues(alpha: 0.3),
      dividerColor: AppColors.divider,
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textDark,
        displayColor: AppColors.textDark,
      ),
    );
  }
}
