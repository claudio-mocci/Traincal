import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';

class WeekSelector extends StatelessWidget {
  const WeekSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final theme = Theme.of(context);
    final start = s.selectedWeek;
    final end = start.add(const Duration(days: 6));
    final f = DateFormat('d MMM');
    final isCurrent = start == mondayOf(DateTime.now());
    Widget arrow(IconData icon, int days, String tip) => IconButton.filledTonal(
      tooltip: tip,
      style: IconButton.styleFrom(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      icon: Icon(icon, size: 20),
      onPressed: () => s.selectWeek(start.add(Duration(days: days))),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: isCurrent ? null : () => s.selectWeek(DateTime.now()),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCurrent ? 'Questa settimana' : 'Torna a oggi',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      '${f.format(start)} – ${f.format(end)}',
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
          arrow(Icons.chevron_left_rounded, -7, 'Settimana precedente'),
          const SizedBox(width: 6),
          arrow(Icons.chevron_right_rounded, 7, 'Settimana successiva'),
        ],
      ),
    );
  }
}
