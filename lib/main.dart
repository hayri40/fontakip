import 'package:flutter/material.dart';

import 'core/app_initializer.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeApp();
  runApp(const FonTakipApp());
}

class FonTakipApp extends StatelessWidget {
  const FonTakipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FonTakip',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F1117),
      ),
      home: const HomeScreen(),
    );
  }
}
