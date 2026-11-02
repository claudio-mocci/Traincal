import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'state/app_state.dart';
import 'ui/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('it_IT');
  Intl.defaultLocale = 'it_IT';
  final state = AppState();
  runApp(
    ChangeNotifierProvider.value(value: state, child: const TraincalApp()),
  );
  await state.init();
}

class TraincalApp extends StatelessWidget {
  const TraincalApp({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeData theme(Brightness b) => ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00897B),
        brightness: b,
      ),
      useMaterial3: true,
    );
    return MaterialApp(
      title: 'Traincal',
      debugShowCheckedModeBanner: false,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      home: Consumer<AppState>(
        builder: (context, s, _) => s.ready
            ? const HomeShell()
            : const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
    );
  }
}
