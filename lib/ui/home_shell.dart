import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'screens/mealprep_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/recipes_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/week_screen.dart';
import 'screens/workouts_screen.dart';
import 'widgets/common.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _destinations = [
    (icon: Icons.calendar_view_week, label: 'Settimana'),
    (icon: Icons.directions_run, label: 'Allenamenti'),
    (icon: Icons.kitchen, label: 'Meal prep'),
    (icon: Icons.menu_book, label: 'Ricette'),
    (icon: Icons.person, label: 'Profilo'),
  ];

  static const _pages = [
    WeekScreen(),
    WorkoutsScreen(),
    MealPrepScreen(),
    RecipesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final wide = MediaQuery.sizeOf(context).width >= 800;

    final appBar = AppBar(
      title: Text(_destinations[_index].label),
      actions: [
        if (s.syncing)
          const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          IconButton(
            tooltip: s.lastIntervalsSync == null
                ? 'Sincronizza'
                : 'Sincronizza (ultima: ${timeFmt.format(s.lastIntervalsSync!)})',
            icon: Icon(s.lastError == null ? Icons.sync : Icons.sync_problem),
            onPressed: s.syncAll,
          ),
        IconButton(
          tooltip: 'Connessioni',
          icon: const Icon(Icons.settings),
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
      ],
    );

    final body = Column(
      children: [
        if (s.lastError != null)
          MaterialBanner(
            content: Text(s.lastError!),
            leading: const Icon(Icons.warning_amber),
            actions: [
              TextButton(onPressed: s.clearError, child: const Text('Chiudi')),
            ],
          ),
        // Su desktop le pagine restano leggibili, centrate.
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: _pages[_index],
            ),
          ),
        ),
      ],
    );

    if (wide) {
      return Scaffold(
        appBar: appBar,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              labelType: NavigationRailLabelType.all,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: appBar,
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final d in _destinations)
            NavigationDestination(icon: Icon(d.icon), label: d.label),
        ],
      ),
    );
  }
}
