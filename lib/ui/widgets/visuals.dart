import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/recipe.dart';
import '../../models/workout.dart';
import '../theme.dart';

/// Anello a segmenti (es. ripartizione delle kcal tra i macro) con un
/// contenuto al centro.
class MacroDonut extends StatelessWidget {
  final List<(double, Color)> segments;
  final Color track;
  final double size;
  final double stroke;
  final Widget child;

  const MacroDonut({
    super.key,
    required this.segments,
    required this.track,
    required this.child,
    this.size = 136,
    this.stroke = 13,
  });

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _DonutPainter(segments, track, stroke),
      child: Center(child: child),
    ),
  );
}

class _DonutPainter extends CustomPainter {
  final List<(double, Color)> segments;
  final Color track;
  final double stroke;

  _DonutPainter(this.segments, this.track, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final r = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, 2 * pi, false, paint..color = track);
    final total = segments.fold<double>(0, (a, s) => a + s.$1);
    if (total <= 0) return;
    // Piccolo spazio tra i segmenti, compensando i bordi arrotondati.
    final gap = stroke / r.width * 2.2;
    var start = -pi / 2;
    for (final (value, color) in segments) {
      final sweep = 2 * pi * value / total;
      if (sweep > gap) {
        canvas.drawArc(
          r,
          start + gap / 2,
          sweep - gap,
          false,
          paint..color = color,
        );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => true;
}

/// Barra orizzontale di un macro: etichetta, valore e avanzamento.
class MacroBar extends StatelessWidget {
  final String label;
  final double value;
  final double? target;
  final Color color;
  final Color? textColor;
  final Color? mutedColor;
  final Color? trackColor;
  final String unit;

  const MacroBar({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.target,
    this.textColor,
    this.mutedColor,
    this.trackColor,
    this.unit = ' g',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = target;
    final progress = t == null || t == 0 ? 1.0 : value / t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: mutedColor ?? theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${value.round()}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: t == null ? unit : '/${t.round()}$unit',
                    style: TextStyle(
                      color: mutedColor ?? theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              style: theme.textTheme.labelMedium?.copyWith(color: textColor),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1).toDouble(),
            minHeight: 7,
            color: color,
            backgroundColor: trackColor ?? color.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }
}

/// Striscia orizzontale dei giorni della settimana (Lun 9, Mar 10, ...).
class DayStrip extends StatelessWidget {
  final List<DateTime> days;
  final int selected;
  final ValueChanged<int> onSelected;

  /// Pallino sotto la data (es. giorni con allenamenti).
  final bool Function(int index)? marked;

  const DayStrip({
    super.key,
    required this.days,
    required this.selected,
    required this.onSelected,
    this.marked,
  });

  static final _wd = DateFormat('EEE');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final today = DateTime.now();
    return Row(
      children: [
        for (var i = 0; i < days.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _DayPill(
                weekday: _wd.format(days[i]),
                day: '${days[i].day}',
                selected: i == selected,
                today: DateUtils.isSameDay(days[i], today),
                marked: marked?.call(i) ?? false,
                onTap: () => onSelected(i),
                scheme: cs,
                theme: theme,
              ),
            ),
          ),
      ],
    );
  }
}

class _DayPill extends StatelessWidget {
  final String weekday;
  final String day;
  final bool selected;
  final bool today;
  final bool marked;
  final VoidCallback onTap;
  final ColorScheme scheme;
  final ThemeData theme;

  const _DayPill({
    required this.weekday,
    required this.day,
    required this.selected,
    required this.today,
    required this.marked,
    required this.onTap,
    required this.scheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : scheme.onSurface;
    return Material(
      color: selected ? scheme.primary : scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected
              ? scheme.primary
              : today
              ? scheme.primary.withValues(alpha: 0.5)
              : scheme.outlineVariant,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                child: Text(
                  weekday,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.85)
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                day,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: marked
                      ? (selected ? Colors.white : context.colors.sport)
                      : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Riquadro colorato con icona che rappresenta un piatto: colore e icona
/// dipendono dalla fonte proteica e dal tipo di pasto.
class FoodTile extends StatelessWidget {
  final Recipe recipe;
  final double size;

  const FoodTile(this.recipe, {super.key, this.size = 56});

  static (IconData, List<Color>) styleFor(Recipe r) {
    if (r.type == MealType.breakfast) {
      return (
        Icons.breakfast_dining_rounded,
        const [Color(0xFFFFC46B), Color(0xFFFF9F43)],
      );
    }
    if (r.type == MealType.snack) {
      return (
        Icons.apple_rounded,
        const [Color(0xFFFF9BB0), Color(0xFFFF6F91)],
      );
    }
    return switch (r.mainProtein) {
      'pesce' => (
        Icons.set_meal_rounded,
        const [Color(0xFF6BC7FF), Color(0xFF3D8BFF)],
      ),
      'pollo' || 'tacchino' => (
        Icons.kebab_dining_rounded,
        const [Color(0xFFFFB36B), Color(0xFFFF7A3D)],
      ),
      'manzo' || 'maiale' || 'carne' => (
        Icons.outdoor_grill_rounded,
        const [Color(0xFFFF8A80), Color(0xFFE5484D)],
      ),
      'uova' => (
        Icons.egg_alt_rounded,
        const [Color(0xFFFFD86B), Color(0xFFFFB020)],
      ),
      'legumi' || 'vegetale' => (
        Icons.eco_rounded,
        const [Color(0xFF7BE0A8), Color(0xFF1FB574)],
      ),
      'latticini' => (
        Icons.icecream_rounded,
        const [Color(0xFFB9A8FF), Color(0xFF7B6CF6)],
      ),
      _ => (
        Icons.rice_bowl_rounded,
        const [Color(0xFFFFB36B), Color(0xFFFF6B2C)],
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (icon, colors) = styleFor(recipe);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.5),
    );
  }
}

/// Riquadro con l'icona dello sport, sullo stesso stile di [FoodTile].
class SportTile extends StatelessWidget {
  final Sport sport;
  final double size;

  const SportTile(this.sport, {super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final c = context.colors.sport;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        switch (sport) {
          Sport.run => Icons.directions_run_rounded,
          Sport.ride => Icons.directions_bike_rounded,
          Sport.strength => Icons.fitness_center_rounded,
          Sport.swim => Icons.pool_rounded,
          Sport.walk => Icons.hiking_rounded,
          Sport.other => Icons.sports_rounded,
        },
        color: c,
        size: size * 0.52,
      ),
    );
  }
}

/// Pillola informativa con icona (es. "20 min", "520 kcal").
class InfoPill extends StatelessWidget {
  final IconData? icon;
  final String text;
  final Color? color;
  final Color? background;

  const InfoPill(
    this.text, {
    super.key,
    this.icon,
    this.color,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? context.colors.subtle,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: c,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card scura in evidenza, con un alone arancio decorativo.
class HeroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const HeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.hero,
        borderRadius: BorderRadius.circular(AppTheme.radius + 4),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -60,
            top: -70,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primary.withValues(alpha: 0.45),
                    primary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
