import 'dart:math';
import '../models/board_coordinate.dart';
import '../pieces/chess_piece.dart';
import '../pieces/game_state.dart';

/// AI using Minimax with Alpha-Beta Pruning (depth 3).
/// Plays as black. Evaluates positions based on material and positional advantage.
class SimpleAI {
  static const int _maxDepth = 3;
  final Random _rng = Random();

  /// Piece values for position evaluation.
  static const Map<PieceType, int> _pieceValues = {
    PieceType.king: 10000,
    PieceType.rook: 500,
    PieceType.bishop: 330,
    PieceType.knight: 320,
  };

  /// Returns a (piece, destination) pair, or null if no moves available.
  ({ChessPiece piece, TilePosition destination})? pickMove(GameState state) {
    final allMoves = state.allLegalMoves();
    if (allMoves.isEmpty) return null;

    // Flatten all moves into a list
    final moves = <({ChessPiece piece, TilePosition destination})>[];
    for (final entry in allMoves.entries) {
      for (final dest in entry.value) {
        moves.add((piece: entry.key, destination: dest));
      }
    }

    if (moves.isEmpty) return null;

    // Immediate king capture wins the game
    for (final move in moves) {
      final target = state.pieceAt(move.destination);
      if (target != null && target.type == PieceType.king) return move;
    }

    // Run minimax on each candidate move and select the best
    var bestScore = -999999;
    final bestMoves = <({ChessPiece piece, TilePosition destination})>[];

    for (final move in moves) {
      final simState = _cloneState(state);
      simState.move(move.piece, move.destination);

      final score = _minimax(
        simState,
        _maxDepth - 1,
        -999999,
        999999,
        false, // next level is opponent (minimizing)
      );

      if (score > bestScore) {
        bestScore = score;
        bestMoves.clear();
        bestMoves.add(move);
      } else if (score == bestScore) {
        bestMoves.add(move);
      }
    }

    // Among equally scored best moves, pick randomly for variety
    return bestMoves[_rng.nextInt(bestMoves.length)];
  }

  /// Minimax with alpha-beta pruning.
  /// [isMaximizing] = true when it's the AI's turn (black).
  int _minimax(
    GameState state,
    int depth,
    int alpha,
    int beta,
    bool isMaximizing,
  ) {
    // Terminal: game ended
    if (!state.isOngoing) return _evaluateTerminal(state);
    // Leaf: depth exhausted
    if (depth == 0) return _evaluate(state);

    final allMoves = state.allLegalMoves();
    // No moves available (stalemate-like)
    if (allMoves.isEmpty) return _evaluate(state);

    if (isMaximizing) {
      var maxEval = -999999;
      for (final entry in allMoves.entries) {
        for (final dest in entry.value) {
          // Instant win detection
          final target = state.pieceAt(dest);
          if (target != null && target.type == PieceType.king) return 99999;

          final simState = _cloneState(state);
          simState.move(entry.key, dest);
          final eval = _minimax(simState, depth - 1, alpha, beta, false);
          if (eval > maxEval) maxEval = eval;
          if (eval > alpha) alpha = eval;
          if (beta <= alpha) return maxEval; // prune
        }
      }
      return maxEval;
    } else {
      var minEval = 999999;
      for (final entry in allMoves.entries) {
        for (final dest in entry.value) {
          // Instant loss detection
          final target = state.pieceAt(dest);
          if (target != null && target.type == PieceType.king) return -99999;

          final simState = _cloneState(state);
          simState.move(entry.key, dest);
          final eval = _minimax(simState, depth - 1, alpha, beta, true);
          if (eval < minEval) minEval = eval;
          if (eval < beta) beta = eval;
          if (beta <= alpha) return minEval; // prune
        }
      }
      return minEval;
    }
  }

  /// Evaluate a terminal (game-over) position.
  int _evaluateTerminal(GameState state) {
    if (state.status == GameStatus.blackWins) return 99999;
    if (state.status == GameStatus.whiteWins) return -99999;
    return 0; // draw
  }

  /// Heuristic evaluation from black's perspective.
  /// Considers material balance and positional factors.
  int _evaluate(GameState state) {
    var score = 0;

    for (final piece in state.pieces.values) {
      final materialValue = _pieceValues[piece.type] ?? 0;
      final positionalBonus = _positionalValue(piece);
      final totalValue = materialValue + positionalBonus;

      if (piece.color == PlayerColor.black) {
        score += totalValue;
      } else {
        score -= totalValue;
      }
    }

    // Small mobility bonus as tiebreaker
    score += _mobilityScore(state);

    return score;
  }

  /// Positional bonus: reward central and advanced positions.
  int _positionalValue(ChessPiece piece) {
    final row = piece.position.row;
    final col = piece.position.col;

    // Reward central columns (assuming ~5-8 col board, center around 2-4)
    final colCenter = (col - 3).abs();
    final centralBonus = max(0, 3 - colCenter) * 5;

    // For black pieces, advancing (lower row numbers) is good
    // For white pieces, advancing (higher row numbers) is good
    int advanceBonus;
    if (piece.color == PlayerColor.black) {
      advanceBonus = max(0, (6 - row)) * 3; // reward moving toward row 0
    } else {
      advanceBonus = row * 3; // reward moving toward higher rows
    }

    // King should stay back (safety)
    if (piece.type == PieceType.king) {
      return centralBonus ~/ 2; // kings get less positional bonus
    }

    return centralBonus + advanceBonus;
  }

  /// Mobility score: count of available moves weighted by current turn.
  int _mobilityScore(GameState state) {
    final moves = state.allLegalMoves();
    var moveCount = 0;
    for (final destinations in moves.values) {
      moveCount += destinations.length;
    }
    // If it's black's turn (AI), more mobility is positive
    if (state.currentTurn == PlayerColor.black) {
      return moveCount * 2;
    } else {
      return -moveCount * 2;
    }
  }

  /// Create a simulation copy of the game state.
  GameState _cloneState(GameState state) {
    return GameState(
      board: state.board,
      initialPieces: Map<TilePosition, ChessPiece>.from(state.pieces),
      startingTurn: state.currentTurn,
    );
  }
}
