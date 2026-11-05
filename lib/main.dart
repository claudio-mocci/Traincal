import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'state/app_state.dart';
import 'ui/home_shell.dart';
import 'ui/theme.dart';

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
    return MaterialApp(
      title: 'Traincal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(Brightness.light),
      darkTheme: AppTheme.build(Brightness.dark),
      home: Consumer<AppState>(
        builder: (context, s, _) => s.ready
            ? const HomeShell()
            : const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
    );
  }
}
