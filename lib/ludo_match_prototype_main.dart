import 'package:flutter/material.dart';
import 'package:ludo_rank/features/ludo_game/presentation/pages/ludo_match_prototype_page.dart';

void main() {
  runApp(const LudoRankPrototypeApp());
}

class LudoRankPrototypeApp extends StatelessWidget {
  const LudoRankPrototypeApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF171321);

    return MaterialApp(
      title: 'LudoRank UI Prototype',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B65D8),
          brightness: Brightness.dark,
          surface: const Color(0xFF241D30),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const LudoMatchPrototypePage(),
    );
  }
}
