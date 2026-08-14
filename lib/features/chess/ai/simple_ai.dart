import 'dart:math';
import '../models/board_coordinate.dart';
import '../pieces/chess_piece.dart';
import '../pieces/game_state.dart';

/// A simple AI that picks a random legal move.
/// Prefers captures and king-targeting moves when available.
class SimpleAI {
  final Random _rng = Random();

  /// Returns a (piece, destination) pair, or null if no moves available.
  ({ChessPiece piece, TilePosition destination})? pickMove(GameState state) {
    final allMoves = state.allLegalMoves();
    if (allMoves.isEmpty) return null;

    // Collect all possible (piece, dest) pairs
    final moves = <({ChessPiece piece, TilePosition destination})>[];
    final captures = <({ChessPiece piece, TilePosition destination})>[];

    for (final entry in allMoves.entries) {
      for (final dest in entry.value) {
        final move = (piece: entry.key, destination: dest);
        moves.add(move);
        // Check if this is a capture (especially king capture)
        final target = state.pieceAt(dest);
        if (target != null) {
          captures.add(move);
          // Instant win: capture the king
          if (target.type == PieceType.king) return move;
        }
      }
    }

    // Prefer captures 70% of the time if available
    if (captures.isNotEmpty && _rng.nextDouble() < 0.7) {
      return captures[_rng.nextInt(captures.length)];
    }

    // Otherwise pick a random move
    return moves[_rng.nextInt(moves.length)];
  }
}
