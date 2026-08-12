import 'package:flutter/material.dart';
import 'features/chess/ui/intro_screen.dart';
import 'features/chess/ui/chess_colors.dart';

void main() => runApp(const ViracochaChessApp());

class ViracochaChessApp extends StatelessWidget {
  const ViracochaChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Viracocha Chess',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: ChessColors.background,
        colorScheme: const ColorScheme.dark(
          primary: ChessColors.gold,
          secondary: ChessColors.moduleBorder,
          surface: ChessColors.deepPurple,
        ),
      ),
      home: const IntroScreen(),
    );
  }
}
