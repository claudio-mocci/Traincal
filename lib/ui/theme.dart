import 'package:flutter/material.dart';

/// Colori del brand e dei macronutrienti, accessibili con
/// `Theme.of(context).extension<AppColors>()!` o `context.colors`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  /// Card in evidenza (giorno selezionato, riepiloghi): antracite in chiaro,
  /// leggermente più chiara del fondo in scuro.
  final Color hero;
  final Color onHero;
  final Color onHeroMuted;
  final Color protein;
  final Color carbs;
  final Color fat;
  final Color kcal;

  /// Allenamenti e attività sportive.
  final Color sport;
  final Color success;

  /// Fondo delle superfici secondarie (pillole, riquadri neutri).
  final Color subtle;

  const AppColors({
    required this.hero,
    required this.onHero,
    required this.onHeroMuted,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.kcal,
    required this.sport,
    required this.success,
    required this.subtle,
  });

  static const light = AppColors(
    hero: Color(0xFF1E1F26),
    onHero: Colors.white,
    onHeroMuted: Color(0xFFA9ABB8),
    protein: Color(0xFFFF5A5F),
    carbs: Color(0xFFFFAA2B),
    fat: Color(0xFF7B6CF6),
    kcal: Color(0xFFFF6B2C),
    sport: Color(0xFF12B886),
    success: Color(0xFF2FB344),
    subtle: Color(0xFFF3EEEA),
  );

  static const dark = AppColors(
    hero: Color(0xFF262833),
    onHero: Colors.white,
    onHeroMuted: Color(0xFF9EA1B0),
    protein: Color(0xFFFF7478),
    carbs: Color(0xFFFFBA4D),
    fat: Color(0xFF9488FF),
    kcal: Color(0xFFFF8148),
    sport: Color(0xFF2FD3A0),
    success: Color(0xFF4CC95F),
    subtle: Color(0xFF23242B),
  );

  @override
  AppColors copyWith({
    Color? hero,
    Color? onHero,
    Color? onHeroMuted,
    Color? protein,
    Color? carbs,
    Color? fat,
    Color? kcal,
    Color? sport,
    Color? success,
    Color? subtle,
  }) => AppColors(
    hero: hero ?? this.hero,
    onHero: onHero ?? this.onHero,
    onHeroMuted: onHeroMuted ?? this.onHeroMuted,
    protein: protein ?? this.protein,
    carbs: carbs ?? this.carbs,
    fat: fat ?? this.fat,
    kcal: kcal ?? this.kcal,
    sport: sport ?? this.sport,
    success: success ?? this.success,
    subtle: subtle ?? this.subtle,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      hero: l(hero, other.hero),
      onHero: l(onHero, other.onHero),
      onHeroMuted: l(onHeroMuted, other.onHeroMuted),
      protein: l(protein, other.protein),
      carbs: l(carbs, other.carbs),
      fat: l(fat, other.fat),
      kcal: l(kcal, other.kcal),
      sport: l(sport, other.sport),
      success: l(success, other.success),
      subtle: l(subtle, other.subtle),
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

class AppTheme {
  static const brand = Color(0xFFFF6B2C);
  static const radius = 22.0;

  static ThemeData build(Brightness b) {
    final dark = b == Brightness.dark;
    final colors = dark ? AppColors.dark : AppColors.light;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: brand,
          brightness: b,
          dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
        ).copyWith(
          primary: dark ? const Color(0xFFFF8148) : brand,
          onPrimary: Colors.white,
          secondary: colors.sport,
          surface: dark ? const Color(0xFF15161B) : const Color(0xFFFAF7F4),
          surfaceContainerLowest: dark ? const Color(0xFF1B1C22) : Colors.white,
          surfaceContainerLow: dark ? const Color(0xFF1E1F25) : Colors.white,
          surfaceContainer: dark
              ? const Color(0xFF22232A)
              : const Color(0xFFF5F0EC),
          onSurface: dark ? const Color(0xFFF2F2F5) : const Color(0xFF1E1F26),
          onSurfaceVariant: dark
              ? const Color(0xFFA7A9B6)
              : const Color(0xFF73757F),
          outlineVariant: dark
              ? const Color(0xFF30323B)
              : const Color(0xFFEAE4DF),
        );

    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: scheme.surface,
      extensions: [colors],
    );
    final text = base.textTheme;
    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    final pill = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(40),
    );

    return base.copyWith(
      textTheme: text.copyWith(
        headlineSmall: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleLarge: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(
          fontFamily: 'Poppins',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: rounded.copyWith(side: BorderSide(color: scheme.outlineVariant)),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: rounded,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: pill,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: pill,
          side: BorderSide(color: scheme.outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: pill),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: pill,
      ),
      chipTheme: ChipThemeData(
        shape: pill,
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: scheme.surfaceContainerLowest,
        selectedColor: scheme.primary,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          fontSize: 13,
          color: scheme.onSurface,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(pill),
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.outlineVariant),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.surfaceContainerLowest,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? Colors.white
                : scheme.onSurface,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        indicatorColor: scheme.primary,
        indicatorShape: pill,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected)
                ? Colors.white
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: s.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primary,
        indicatorShape: pill,
        selectedIconTheme: const IconThemeData(color: Colors.white),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: scheme.primary,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: scheme.onSurfaceVariant,
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 24),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.primary : null,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
