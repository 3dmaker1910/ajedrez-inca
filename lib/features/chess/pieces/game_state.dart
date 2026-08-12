import '../board/game_board.dart';
import '../models/board_coordinate.dart';
import 'chess_piece.dart';
import 'movement_calculator.dart';

/// Possible game states.
enum GameStatus { ongoing, whiteWins, blackWins, draw }

/// Manages active pieces, turn tracking, and win condition.
///
/// Win condition: **Capturing the King ends the game**.
class GameState {
  final GameBoard board;
  final Map<TilePosition, ChessPiece> _pieces;
  PlayerColor _currentTurn;
  GameStatus _status;
  final List<String> moveHistory = [];

  GameState({
    required this.board,
    Map<TilePosition, ChessPiece>? initialPieces,
    PlayerColor startingTurn = PlayerColor.white,
  })  : _pieces = initialPieces ?? {},
        _currentTurn = startingTurn,
        _status = GameStatus.ongoing;

  // ─── Accessors ─────────────────────────────────────────────────────────────

  Map<TilePosition, ChessPiece> get pieces => Map.unmodifiable(_pieces);
  PlayerColor get currentTurn => _currentTurn;
  GameStatus  get status      => _status;
  bool        get isOngoing   => _status == GameStatus.ongoing;

  ChessPiece? pieceAt(TilePosition pos) => _pieces[pos];

  // ─── Setup ─────────────────────────────────────────────────────────────────

  /// Place a piece directly (used during board setup, before game starts).
  void addPiece(ChessPiece piece) => _pieces[piece.position] = piece;

  // ─── Move Execution ────────────────────────────────────────────────────────

  /// Attempts to move [piece] to [destination].
  /// Returns `true` on success, `false` if illegal.
  bool move(ChessPiece piece, TilePosition destination) {
    if (!isOngoing) return false;
    if (piece.color != _currentTurn) return false;

    final calculator = MovementCalculator(board: board, pieceMap: _pieces);
    final legal = calculator.legalMoves(piece);
    if (!legal.contains(destination)) return false;

    // Perform the move
    _pieces.remove(piece.position);
    final captured = _pieces[destination];
    final moved = piece.copyWith(position: destination);
    _pieces[destination] = moved;

    // Record
    moveHistory.add(
      '${piece.color.name}: ${piece.type.name} '
      '${piece.position}→$destination'
      '${captured != null ? " x${captured.type.name}" : ""}',
    );

    // Check win condition (capturing the King ends the game)
    if (captured?.type == PieceType.king) {
      _status = piece.color == PlayerColor.white
          ? GameStatus.whiteWins
          : GameStatus.blackWins;
      return true;
    }

    _switchTurn();
    return true;
  }

  /// Returns all legal moves for the current player.
  Map<ChessPiece, List<TilePosition>> allLegalMoves() {
    final calculator = MovementCalculator(board: board, pieceMap: _pieces);
    final result = <ChessPiece, List<TilePosition>>{};
    for (final piece in _pieces.values.where((p) => p.color == _currentTurn)) {
      final moves = calculator.legalMoves(piece);
      if (moves.isNotEmpty) result[piece] = moves;
    }
    return result;
  }

  void _switchTurn() {
    _currentTurn = _currentTurn == PlayerColor.white
        ? PlayerColor.black
        : PlayerColor.white;
  }
}
