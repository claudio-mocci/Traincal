import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';

class WeekSelector extends StatelessWidget {
  const WeekSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final start = s.selectedWeek;
    final end = start.add(const Duration(days: 6));
    final f = DateFormat('d MMM');
    final isCurrent = start == mondayOf(DateTime.now());
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () =>
              s.selectWeek(start.subtract(const Duration(days: 7))),
        ),
        Flexible(
          child: TextButton(
            onPressed: isCurrent ? null : () => s.selectWeek(DateTime.now()),
            child: Text(
              '${f.format(start)} – ${f.format(end)}'
              '${isCurrent ? ' · questa settimana' : ''}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => s.selectWeek(start.add(const Duration(days: 7))),
        ),
      ],
    );
  }
}
