import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/food.dart';
import '../../models/workout.dart';

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

/// Riga compatta con kcal e macro.
class MacroRow extends StatelessWidget {
  final Macros m;
  final Macros? target;
  final bool dense;

  const MacroRow(this.m, {super.key, this.target, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget chip(String label, double v, double? t, Color c) {
      final text = t == null
          ? '$label ${v.round()}'
          : '$label ${v.round()}/${t.round()}';
      return Container(
        padding: EdgeInsets.symmetric(horizontal: dense ? 6 : 8, vertical: 2),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: dense ? 12 : 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        chip('kcal', m.kcal, target?.kcal, cs.primary),
        chip('P', m.protein, target?.protein, Colors.red),
        chip('C', m.carbs, target?.carbs, Colors.amber.shade700),
        chip('G', m.fat, target?.fat, Colors.blue),
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
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
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
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    ),
  );
}
