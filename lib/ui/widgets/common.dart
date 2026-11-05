import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/food.dart';
import '../../models/workout.dart';
import '../theme.dart';

final dayFmt = DateFormat('EEE d MMM');
final dayLongFmt = DateFormat('EEEE d MMMM');
final timeFmt = DateFormat('HH:mm');

String fmtDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  return h > 0 ? '${h}h${m.toString().padLeft(2, '0')}' : '$m min';
}

String fmtServings(double s) => s == s.roundToDouble()
    ? s.toStringAsFixed(0)
    : s.toStringAsFixed(2).replaceAll(RegExp(r'0$'), '');

IconData sportIcon(Sport s) => switch (s) {
  Sport.run => Icons.directions_run,
  Sport.ride => Icons.directions_bike,
  Sport.strength => Icons.fitness_center,
  Sport.swim => Icons.pool,
  Sport.walk => Icons.hiking,
  Sport.other => Icons.sports,
};

/// Riga compatta con kcal e macro, come pillole con pallino colorato.
class MacroRow extends StatelessWidget {
  final Macros m;
  final Macros? target;
  final bool dense;

  const MacroRow(this.m, {super.key, this.target, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context);
    Widget chip(String label, double v, double? t, Color color) {
      final value = t == null ? '${v.round()}' : '${v.round()}/${t.round()}';
      return Container(
        padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label ',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              style: TextStyle(fontSize: dense ? 11.5 : 12.5),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        chip('kcal', m.kcal, target?.kcal, c.kcal),
        chip('P', m.protein, target?.protein, c.protein),
        chip('C', m.carbs, target?.carbs, c.carbs),
        chip('G', m.fat, target?.fat, c.fat),
      ],
    );
  }
}

void showError(BuildContext context, Object e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(e.toString()),
      backgroundColor: Theme.of(context).colorScheme.error,
    ),
  );
}

void showInfo(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

/// Esegue un'operazione asincrona mostrando eventuali errori.
Future<T?> guarded<T>(BuildContext context, Future<T> Function() f) async {
  try {
    return await f();
  } catch (e) {
    if (context.mounted) showError(context, e);
    return null;
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 12, 10),
    child: Row(
      children: [
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.titleMedium),
        ),
        ?trailing,
      ],
    ),
  );
}

class EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;

  const EmptyHint({
    super.key,
    required this.icon,
    required this.text,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: primary),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
