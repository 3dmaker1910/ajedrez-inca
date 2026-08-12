import 'package:flutter/material.dart';
import '../board/game_board.dart';
import '../models/board_coordinate.dart';
import '../models/tile.dart';
import '../pieces/chess_piece.dart';
import 'chess_colors.dart';

/// Renders the entire [GameBoard] using a [CustomPainter].
///
/// Layout assumptions (all derived from [tileSize]):
///  • Each tile is [tileSize]×[tileSize] pixels.
///  • Module borders are 2px wider than tile borders.
class BoardPainter extends CustomPainter {
  final GameBoard board;
  final Map<TilePosition, ChessPiece> pieces;
  final TilePosition? selectedTile;
  final List<TilePosition> possibleMoves;
  final double tileSize;

  const BoardPainter({
    required this.board,
    required this.pieces,
    this.selectedTile,
    this.possibleMoves = const [],
    this.tileSize = 48,
  });

  // ─── Paint ─────────────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    final b = board.bounds;
    if (b == null) return;

    final rowOffset = b.minRow;
    final colOffset = b.minCol;

    // ── 1. Tile backgrounds ──────────────────────────────────────────────────
    for (int r = b.minRow; r <= b.maxRow; r++) {
      for (int c = b.minCol; c <= b.maxCol; c++) {
        final pos   = TilePosition(r, c);
        final tile  = board.tileAt(pos);
        if (tile == null) continue;

        final rect = _rectForPos(r, c, rowOffset, colOffset);

        // Checkerboard colouring for normal tiles
        Color bg;
        if (tile.isVoid) {
          bg = ChessColors.voidTile;
        } else {
          bg = (r + c).isEven ? ChessColors.normalTileA : ChessColors.normalTileB;
        }

        canvas.drawRect(rect, Paint()..color = bg);

        // Highlight: selected
        if (selectedTile == pos) {
          canvas.drawRect(
            rect,
            Paint()
              ..color = ChessColors.selectedTile.withOpacity(0.55)
              ..blendMode = BlendMode.srcOver,
          );
        }

        // Highlight: possible move
        if (possibleMoves.contains(pos)) {
          canvas.drawCircle(
            rect.center,
            tileSize * 0.22,
            Paint()..color = ChessColors.possibleMove,
          );
        }
      }
    }

    // ── 2. Module borders ────────────────────────────────────────────────────
    for (final coord in board.modules.keys) {
      final startR = coord.y * 3;
      final startC = coord.x * 3;
      final left   = (startC - colOffset) * tileSize;
      final top    = (startR - rowOffset) * tileSize;
      final rect   = Rect.fromLTWH(left, top, tileSize * 3, tileSize * 3);
      canvas.drawRect(
        rect,
        Paint()
          ..color = ChessColors.moduleBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    // ── 3. Tile grid lines ───────────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = ChessColors.moduleBorder.withOpacity(0.25)
      ..strokeWidth = 0.5;

    final b2 = board.bounds!;
    for (int r = b2.minRow; r <= b2.maxRow + 1; r++) {
      final y = (r - rowOffset) * tileSize;
      canvas.drawLine(
        Offset(0, y),
        Offset((b2.maxCol - b2.minCol + 1) * tileSize, y),
        gridPaint,
      );
    }
    for (int c = b2.minCol; c <= b2.maxCol + 1; c++) {
      final x = (c - colOffset) * tileSize;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, (b2.maxRow - b2.minRow + 1) * tileSize),
        gridPaint,
      );
    }

    // ── 4. Pieces ────────────────────────────────────────────────────────────
    for (final entry in pieces.entries) {
      final pos  = entry.key;
      final p    = entry.value;
      if (!board.isNormalTile(pos)) continue;
      final rect = _rectForPos(pos.row, pos.col, rowOffset, colOffset);
      _drawPiece(canvas, rect, p);
    }
  }

  // ─── Piece drawing ─────────────────────────────────────────────────────────

  void _drawPiece(Canvas canvas, Rect rect, ChessPiece piece) {
    final pieceColor =
        piece.color == PlayerColor.white ? ChessColors.whitepiece : ChessColors.blackPiece;
    final strokeColor = ChessColors.pieceStroke;
    final radius = tileSize * 0.38;
    final center = rect.center;

    // Outer glow for better visibility
    canvas.drawCircle(
      center,
      radius + 2,
      Paint()
        ..color = strokeColor.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(center, radius, Paint()..color = pieceColor);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Draw piece symbol
    final label = _pieceSymbol(piece);
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: piece.color == PlayerColor.white
              ? ChessColors.deepPurple
              : ChessColors.gold,
          fontSize: tileSize * 0.38,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  String _pieceSymbol(ChessPiece piece) {
    switch (piece.type) {
      case PieceType.king:   return '♔';
      case PieceType.rook:   return '♖';
      case PieceType.bishop: return '♗';
      case PieceType.knight: return '♘';
    }
  }

  Rect _rectForPos(int r, int c, int rowOffset, int colOffset) => Rect.fromLTWH(
        (c - colOffset) * tileSize,
        (r - rowOffset) * tileSize,
        tileSize,
        tileSize,
      );

  @override
  bool shouldRepaint(covariant BoardPainter old) =>
      old.board    != board       ||
      old.pieces   != pieces      ||
      old.selectedTile != selectedTile ||
      old.possibleMoves != possibleMoves;
}
