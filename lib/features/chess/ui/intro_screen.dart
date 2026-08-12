import 'package:flutter/material.dart';
import '../audio/chess_audio_manager.dart';
import 'game_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scrollAnimation;
  late Animation<double> _fadeAnimation;

  static const _crawlText = '''
En los Andes del tiempo eterno,
donde los Hijos del Sol gobernaban
con sabiduría y valor...

Nació un juego sagrado.

No era un juego común.
Era la guerra misma.
Una danza de estrategia
entre los Grandes Señores del Tahuantinsuyo.

Siete guerreros por bando.
Un tablero forjado por los propios jugadores.
Módulos de piedra que se ensamblan,
se rotan, se conectan.

Los vacíos son precipicios sagrados.
Solo el Caballo puede cruzarlos.

No hay jaque. No hay rendición.
Solo hay UNA victoria:

CAPTURAR AL REY.

¿Estás listo para reclamar
el Trono del Sol?''';

  @override
  void initState() {
    super.initState();
    ChessAudioManager().playBackgroundMusic();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    _scrollAnimation = Tween<double>(begin: 1.0, end: -1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Auto-navigate after 8 seconds
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) _navigateToGame();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToGame() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Title at top (static)
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: const Text(
                  'AJEDREZ INCA',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 6,
                  ),
                ),
              ),
            ),
          ),

          // Scrolling crawl text with perspective
          Positioned.fill(
            top: 140,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.002)
                      ..rotateX(0.6),
                    child: FractionalTranslation(
                      translation: Offset(0, _scrollAnimation.value),
                      child: child,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFFD700)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds),
                  child: Text(
                    _crawlText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      height: 1.8,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // "COMENZAR" button at bottom
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: const Color(0xFFFFD700),
                  side: const BorderSide(color: Color(0xFFFFD700), width: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _navigateToGame,
                child: const Text(
                  'COMENZAR',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
