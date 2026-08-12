import '../board/game_board.dart';
import '../models/board_coordinate.dart';
import 'chess_piece.dart';

/// Calculates legal destination tiles for a given piece.
///
/// Rules mirror standard chess but are adapted for the modular board:
///   • Movement stops at void tiles (cannot enter or pass through).
///   • Knight EXCEPTION: jumps over void tiles; lands only on normal tiles.
///   • Capturing the King ends the game (handled at game-state level).
class MovementCalculator {
  final GameBoard board;
  final Map<TilePosition, ChessPiece> pieceMap;

  const MovementCalculator({
    required this.board,
    required this.pieceMap,
  });

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Returns all legal destination [TilePosition]s for [piece].
  List<TilePosition> legalMoves(ChessPiece piece) {
    switch (piece.type) {
      case PieceType.king:   return _kingMoves(piece);
      case PieceType.rook:   return _rookMoves(piece);
      case PieceType.bishop: return _bishopMoves(piece);
      case PieceType.knight: return _knightMoves(piece);
    }
  }

  // ─── King ──────────────────────────────────────────────────────────────────

  List<TilePosition> _kingMoves(ChessPiece piece) {
    final moves = <TilePosition>[];
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final target = TilePosition(
          piece.position.row + dr,
          piece.position.col + dc,
        );
        if (_canLand(piece, target)) moves.add(target);
      }
    }
    return moves;
  }

  // ─── Rook ──────────────────────────────────────────────────────────────────

  List<TilePosition> _rookMoves(ChessPiece piece) {
    final moves = <TilePosition>[];
    for (final delta in const [
      TilePosition(-1, 0), // up
      TilePosition(1, 0),  // down
      TilePosition(0, -1), // left
      TilePosition(0, 1),  // right
    ]) {
      _slidingMoves(piece, delta, moves);
    }
    return moves;
  }

  // ─── Bishop ────────────────────────────────────────────────────────────────

  List<TilePosition> _bishopMoves(ChessPiece piece) {
    final moves = <TilePosition>[];
    for (final delta in const [
      TilePosition(-1, -1),
      TilePosition(-1, 1),
      TilePosition(1, -1),
      TilePosition(1, 1),
    ]) {
      _slidingMoves(piece, delta, moves);
    }
    return moves;
  }

  // ─── Knight ────────────────────────────────────────────────────────────────
  // SPECIAL RULE: Knight can jump over void tiles; it only needs the
  // DESTINATION tile to be normal and reachable.

  List<TilePosition> _knightMoves(ChessPiece piece) {
    const offsets = [
      TilePosition(-2, -1), TilePosition(-2, 1),
      TilePosition(-1, -2), TilePosition(-1, 2),
      TilePosition(1,  -2), TilePosition(1,  2),
      TilePosition(2,  -1), TilePosition(2,  1),
    ];
    final moves = <TilePosition>[];
    for (final offset in offsets) {
      final target = TilePosition(
        piece.position.row + offset.row,
        piece.position.col + offset.col,
      );
      if (_canLand(piece, target)) moves.add(target);
    }
    return moves;
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  /// Adds sliding moves along [delta] until blocked or off-board.
  void _slidingMoves(
    ChessPiece piece,
    TilePosition delta,
    List<TilePosition> result,
  ) {
    TilePosition current = TilePosition(
      piece.position.row + delta.row,
      piece.position.col + delta.col,
    );
    while (board.isOnBoard(current)) {
      if (board.isVoidTile(current)) break; // blocked by void
      final occupant = pieceMap[current];
      if (occupant != null) {
        if (occupant.color != piece.color) result.add(current); // capture
        break; // blocked regardless
      }
      result.add(current);
      current = TilePosition(
        current.row + delta.row,
        current.col + delta.col,
      );
    }
  }

  /// Returns true if [piece] can land on [target]:
  /// tile must be normal, on board, and not occupied by friendly piece.
  bool _canLand(ChessPiece piece, TilePosition target) {
    if (!board.isNormalTile(target)) return false;
    final occupant = pieceMap[target];
    return occupant == null || occupant.color != piece.color;
  }
}
