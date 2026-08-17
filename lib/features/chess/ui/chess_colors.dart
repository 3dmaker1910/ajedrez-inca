import 'package:flutter/material.dart';

/// Viracocha Chess design tokens — "Pixar/Nintendo" deep-fantasy palette.
class ChessColors {
  ChessColors._();

  static const Color deepPurple     = Color(0xFF0D0A14);
  static const Color gold           = Color(0xFFD4AF37);
  static const Color goldLight      = Color(0xFFF0D060);
  static const Color goldDark       = Color(0xFF9A7B1A);
  static const Color normalTileA    = Color(0xFF8B2500); // dark square – Terracota Inka
  static const Color normalTileB    = Color(0xFFF0C040); // light square – Dorado cálido
  static const Color voidTile       = Color(0xFF1A3A6B); // abyss – Azul andino (Precipicio)
  static const Color moduleBorder   = Color(0xFF6B4FCF); // purple accent
  static const Color selectedTile   = Color(0xFFFFE066); // bright yellow
  static const Color possibleMove   = Color(0x884FC3F7); // translucent cyan
  static const Color whitepiece     = Color(0xFFF5F0FF);
  static const Color blackPiece     = Color(0xFF1A0A2E);
  static const Color pieceStroke    = Color(0xFFD4AF37);
  static const Color background     = deepPurple;
}
