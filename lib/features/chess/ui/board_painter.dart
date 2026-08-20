import 'package:flutter/material.dart';
import '../board/game_board.dart';
import '../models/board_coordinate.dart';
import '../models/tile.dart';
import '../pieces/chess_piece.dart';
import 'chess_colors.dart';

/// CustomPainter that renders the modular board with visual gaps between modules.
class BoardPainter extends CustomPainter {
  final GameBoard board;
  final Map<TilePosition, ChessPiece> pieces;
  final TilePosition? selectedTile;
  final List<TilePosition> possibleMoves;
  final double tileSize;

  /// Gap between modules (in pixels).
  static const double moduleGap = 3.0;

  BoardPainter({
    required this.board,
    required this.pieces,
    required this.selectedTile,
    required this.possibleMoves,
    required this.tileSize,
  });

  /// Calculate the total canvas size accounting for module gaps.
  static Size totalSize(GameBoard board, double tileSize) {
    final b = board.bounds;
    if (b == null) return Size.zero;
    final moduleCols = ((b.maxCol - b.minCol) ~/ 3) + 1;
    final moduleRows = ((b.maxRow - b.minRow) ~/ 3) + 1;
    final width = moduleCols * 3 * tileSize + (moduleCols - 1) * moduleGap;
    final height = moduleRows * 3 * tileSize + (moduleRows - 1) * moduleGap;
    return Size(width, height);
  }

  /// Convert a world tile position to pixel offset on canvas.
  Offset _tileToPixel(TilePosition pos, ({int minRow, int maxRow, int minCol, int maxCol}) b) {
    final relCol = pos.col - b.minCol;
    final relRow = pos.row - b.minRow;
    // Which module column/row is this tile in?
    final modCol = relCol ~/ 3;
    final modRow = relRow ~/ 3;
    final dx = relCol * tileSize + modCol * moduleGap;
    final dy = relRow * tileSize + modRow * moduleGap;
    return Offset(dx, dy);
  }

  /// Convert pixel offset to world tile position.
  static TilePosition? pixelToTile(
    Offset local,
    GameBoard board,
    double tileSize,
  ) {
    final b = board.bounds;
    if (b == null) return null;
    final moduleCols = ((b.maxCol - b.minCol) ~/ 3) + 1;
    final moduleRows = ((b.maxRow - b.minRow) ~/ 3) + 1;

    // Determine which module column/row we're in
    final moduleWidthWithGap = 3 * tileSize + moduleGap;
    int modCol = (local.dx / moduleWidthWithGap).floor();
    int modRow = (local.dy / moduleWidthWithGap).floor();
    modCol = modCol.clamp(0, moduleCols - 1);
    modRow = modRow.clamp(0, moduleRows - 1);

    // Local offset within the module
    final localInModX = local.dx - modCol * moduleWidthWithGap;
    final localInModY = local.dy - modRow * moduleWidthWithGap;

    // Check if in the gap zone
    if (localInModX < 0 || localInModX >= 3 * tileSize) return null;
    if (localInModY < 0 || localInModY >= 3 * tileSize) return null;

    final tileCol = (localInModX / tileSize).floor();
    final tileRow = (localInModY / tileSize).floor();

    final worldCol = b.minCol + modCol * 3 + tileCol;
    final worldRow = b.minRow + modRow * 3 + tileRow;
    return TilePosition(worldRow, worldCol);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final b = board.bounds;
    if (b == null) return;

    // Draw module backgrounds and borders first
    _drawModuleBackgrounds(canvas, b);

    // Draw tiles
    for (int r = b.minRow; r <= b.maxRow; r++) {
      for (int c = b.minCol; c <= b.maxCol; c++) {
        final pos = TilePosition(r, c);
        final tile = board.tileAt(pos);
        if (tile == null) continue;

        final offset = _tileToPixel(pos, b);
        _drawTile(canvas, offset, pos, tile);
      }
    }

    // Draw pieces
    for (final entry in pieces.entries) {
      final offset = _tileToPixel(entry.key, b);
      _drawPiece(canvas, offset, entry.value);
    }
  }

  void _drawModuleBackgrounds(Canvas canvas, ({int minRow, int maxRow, int minCol, int maxCol}) b) {
    final borderPaint = Paint()
      ..color = ChessColors.moduleBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final coord in board.modules.keys) {
      final relCol = (coord.x * 3) - b.minCol;
      final relRow = (coord.y * 3) - b.minRow;
      final modCol = relCol ~/ 3;
      final modRow = relRow ~/ 3;
      final dx = relCol * tileSize + modCol * moduleGap;
      final dy = relRow * tileSize + modRow * moduleGap;

      final rect = Rect.fromLTWH(dx, dy, 3 * tileSize, 3 * tileSize);
      canvas.drawRect(rect, borderPaint);
    }
  }

  void _drawTile(Canvas canvas, Offset offset, TilePosition pos, Tile tile) {
    final rect = Rect.fromLTWH(offset.dx, offset.dy, tileSize, tileSize);

    if (tile.isVoid) {
      // Void tiles (precipices) \u2014 dark abyss
      final paint = Paint()..color = ChessColors.voidTile;
      canvas.drawRect(rect, paint);
      // Draw a subtle X pattern
      final xPaint = Paint()
        ..color = ChessColors.voidTile.withOpacity(0.3)
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(rect.topLeft, rect.bottomRight, xPaint);
      canvas.drawLine(rect.topRight, rect.bottomLeft, xPaint);
      return;
    }

    // Normal tile \u2014 checkerboard pattern based on world position
    final isDark = (pos.row + pos.col) % 2 == 1;
    final baseColor = isDark ? ChessColors.darkTile : ChessColors.lightTile;

    // Highlight selected
    Color tileColor;
    if (pos == selectedTile) {
      tileColor = ChessColors.selectedTile;
    } else if (possibleMoves.contains(pos)) {
      tileColor = ChessColors.possibleMove;
    } else {
      tileColor = baseColor;
    }

    canvas.drawRect(rect, Paint()..color = tileColor);

    // Tile border
    final borderPaint = Paint()
      ..color = ChessColors.tileBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawRect(rect, borderPaint);
  }

  void _drawPiece(Canvas canvas, Offset offset, ChessPiece piece) {
    final center = Offset(
      offset.dx + tileSize / 2,
      offset.dy + tileSize / 2,
    );

    // Piece background circle
    final bgPaint = Paint()
      ..color = piece.color == PlayerColor.white
          ? ChessColors.whitePiece
          : ChessColors.blackPiece;
    canvas.drawCircle(center, tileSize * 0.38, bgPaint);

    // Piece border
    final borderPaint = Paint()
      ..color = piece.color == PlayerColor.white
          ? ChessColors.blackPiece
          : ChessColors.whitePiece
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, tileSize * 0.38, borderPaint);

    // Piece symbol
    final symbol = _pieceSymbol(piece);
    final textPainter = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(
          fontSize: tileSize * 0.45,
          color: piece.color == PlayerColor.white
              ? ChessColors.blackPiece
              : ChessColors.gold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  String _pieceSymbol(ChessPiece piece) {
    switch (piece.type) {
      case PieceType.king:   return '\u265a';
      case PieceType.rook:   return '\u265c';
      case PieceType.bishop: return '\u265d';
      case PieceType.knight: return '\u265e';
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) =>
      old.board != board ||
      old.pieces != pieces ||
      old.selectedTile != selectedTile ||
      old.possibleMoves != possibleMoves;
}
