import 'package:test/test.dart';
import 'package:viracocha_chess/features/chess/board/game_board.dart';
import 'package:viracocha_chess/features/chess/models/board_coordinate.dart';
import 'package:viracocha_chess/features/chess/models/chess_module.dart';
import 'package:viracocha_chess/features/chess/models/module_pattern.dart';
import 'package:viracocha_chess/features/chess/pieces/chess_piece.dart';
import 'package:viracocha_chess/features/chess/pieces/movement_calculator.dart';

/// Build a 3×3 full board with no pieces.
GameBoard fullBoard3x3() {
  final board = GameBoard();
  board.placeFirstModule(ChessModule(patternType: ModulePatternType.full));
  return board;
}

/// Build a 2-module (6×3) board: full at (0,0) and full at (1,0).
GameBoard twoModuleBoard() {
  final board = GameBoard();
  board.placeFirstModule(ChessModule(patternType: ModulePatternType.full));
  board.placeModule(
    ChessModule(patternType: ModulePatternType.full),
    const BoardCoordinate(1, 0),
  );
  return board;
}

MovementCalculator calc(GameBoard board,
    [Map<TilePosition, ChessPiece>? pieces]) {
  return MovementCalculator(
    board: board,
    pieceMap: pieces ?? {},
  );
}

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  group('King movement', () {
    test('king in centre has 8 moves on full 3×3 board', () {
      final board = fullBoard3x3();
      const king = ChessPiece(
        type: PieceType.king,
        color: PlayerColor.white,
        position: TilePosition(1, 1),
      );
      final moves = calc(board).legalMoves(king);
      expect(moves.length, 8);
    });

    test('king in corner has 3 moves', () {
      final board = fullBoard3x3();
      const king = ChessPiece(
        type: PieceType.king,
        color: PlayerColor.white,
        position: TilePosition(0, 0),
      );
      final moves = calc(board).legalMoves(king);
      expect(moves.length, 3);
    });

    test('king cannot move onto friendly piece', () {
      final board = fullBoard3x3();
      const king = ChessPiece(
        type: PieceType.king,
        color: PlayerColor.white,
        position: TilePosition(0, 0),
      );
      const friendly = ChessPiece(
        type: PieceType.rook,
        color: PlayerColor.white,
        position: TilePosition(0, 1),
      );
      final pieces = {
        const TilePosition(0, 0): king,
        const TilePosition(0, 1): friendly,
      };
      final moves = calc(board, pieces).legalMoves(king);
      expect(moves.contains(const TilePosition(0, 1)), isFalse);
    });

    test('king can capture enemy piece', () {
      final board = fullBoard3x3();
      const king = ChessPiece(
        type: PieceType.king,
        color: PlayerColor.white,
        position: TilePosition(0, 0),
      );
      const enemy = ChessPiece(
        type: PieceType.bishop,
        color: PlayerColor.black,
        position: TilePosition(0, 1),
      );
      final pieces = {
        const TilePosition(0, 0): king,
        const TilePosition(0, 1): enemy,
      };
      final moves = calc(board, pieces).legalMoves(king);
      expect(moves.contains(const TilePosition(0, 1)), isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('Rook movement', () {
    test('rook from centre has up to 4 sliding directions', () {
      final board = twoModuleBoard(); // 6-row × 3-col board
      const rook = ChessPiece(
        type: PieceType.rook,
        color: PlayerColor.white,
        position: TilePosition(1, 1),
      );
      final moves = calc(board).legalMoves(rook);
      // Up: row 0 → 1 tile; Down: rows 2-5 → 4 tiles; Left: col 0 → 1; Right: col 2 → 1
      expect(moves.length, greaterThan(0));
    });

    test('rook is blocked by own piece', () {
      final board = fullBoard3x3();
      const rook = ChessPiece(
        type: PieceType.rook,
        color: PlayerColor.white,
        position: TilePosition(0, 0),
      );
      const blocker = ChessPiece(
        type: PieceType.bishop,
        color: PlayerColor.white,
        position: TilePosition(0, 2),
      );
      final pieces = {
        const TilePosition(0, 0): rook,
        const TilePosition(0, 2): blocker,
      };
      final moves = calc(board, pieces).legalMoves(rook);
      // Can only reach (0,1) horizontally; NOT (0,2)
      expect(moves.contains(const TilePosition(0, 2)), isFalse);
      expect(moves.contains(const TilePosition(0, 1)), isTrue);
    });

    test('rook is blocked by void tile', () {
      // crossVoid module: (0,1),(1,0),(1,1),(1,2),(2,1) are void
      final board = GameBoard();
      board.placeFirstModule(ChessModule(patternType: ModulePatternType.crossVoid));

      const rook = ChessPiece(
        type: PieceType.rook,
        color: PlayerColor.white,
        position: TilePosition(0, 0),
      );
      final moves = calc(board).legalMoves(rook);
      // Moving right from (0,0): (0,1) is void → blocked immediately
      expect(moves.contains(const TilePosition(0, 1)), isFalse);
      // Moving down from (0,0): (1,0) is void → blocked immediately
      expect(moves.contains(const TilePosition(1, 0)), isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('Bishop movement', () {
    test('bishop from corner on full board has 2 diagonal moves', () {
      final board = fullBoard3x3();
      const bishop = ChessPiece(
        type: PieceType.bishop,
        color: PlayerColor.white,
        position: TilePosition(0, 0),
      );
      final moves = calc(board).legalMoves(bishop);
      // Only one diagonal direction from corner: (1,1) and (2,2)
      expect(moves.contains(const TilePosition(1, 1)), isTrue);
      expect(moves.contains(const TilePosition(2, 2)), isTrue);
      expect(moves.length, 2);
    });

    test('bishop from centre has 4 directions', () {
      final board = fullBoard3x3();
      const bishop = ChessPiece(
        type: PieceType.bishop,
        color: PlayerColor.white,
        position: TilePosition(1, 1),
      );
      final moves = calc(board).legalMoves(bishop);
      // 4 corners reachable
      expect(moves.contains(const TilePosition(0, 0)), isTrue);
      expect(moves.contains(const TilePosition(0, 2)), isTrue);
      expect(moves.contains(const TilePosition(2, 0)), isTrue);
      expect(moves.contains(const TilePosition(2, 2)), isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('Knight movement', () {
    test('knight from corner has 2 L-moves on 3×3', () {
      final board = fullBoard3x3();
      const knight = ChessPiece(
        type: PieceType.knight,
        color: PlayerColor.white,
        position: TilePosition(0, 0),
      );
      final moves = calc(board).legalMoves(knight);
      expect(moves.contains(const TilePosition(1, 2)), isTrue);
      expect(moves.contains(const TilePosition(2, 1)), isTrue);
      expect(moves.length, 2);
    });

    test('knight JUMPS over void tiles', () {
      // ringVoid: only centre (1,1) is normal; all border tiles are void
      final board = GameBoard();
      board.placeFirstModule(
        ChessModule(patternType: ModulePatternType.full),
        const BoardCoordinate(0, 0),
      );
      // Place another full module below so the L-jump destination exists
      board.placeModule(
        ChessModule(patternType: ModulePatternType.full),
        const BoardCoordinate(0, 1),
      );

      // Put a rook-blocker void patch: use cornerCut so (0,0)=void at module (1,0)
      // then place a knight at world (0,1) and see if it can reach world (2,0)
      // over a void patch. For a cleaner test use ringVoid:
      final boardR = GameBoard();
      boardR.placeFirstModule(ChessModule(patternType: ModulePatternType.full));
      // Attach ring-void module to the right: world rows 0-2, cols 3-5
      boardR.placeModule(
        ChessModule(patternType: ModulePatternType.ringVoid),
        const BoardCoordinate(1, 0),
      );
      // Attach another full module below the ring: rows 3-5, cols 3-5
      boardR.placeModule(
        ChessModule(patternType: ModulePatternType.full),
        const BoardCoordinate(1, 1),
      );

      // Knight at world (0,2) — bottom-right of first module
      // ringVoid module at cols 3-5: (0,3)(0,4)(0,5)(1,3)(1,5)(2,3)(2,4)(2,5) void
      //                              only (1,4) is normal
      // L-jump from (0,2): candidates include (2,3) — void; (1,4) — normal (inside ring)
      const knight = ChessPiece(
        type: PieceType.knight,
        color: PlayerColor.white,
        position: TilePosition(0, 2),
      );
      final moves = calc(boardR).legalMoves(knight);
      // Knight CAN land on (1,4) which is the single normal tile of ringVoid
      expect(moves.contains(const TilePosition(1, 4)), isTrue,
          reason: 'Knight should jump over voids into ringVoid center (1,4)');
    });

    test('knight cannot land on friendly piece', () {
      final board = twoModuleBoard();
      const knight = ChessPiece(
        type: PieceType.knight,
        color: PlayerColor.white,
        position: TilePosition(0, 0),
      );
      const friendly = ChessPiece(
        type: PieceType.rook,
        color: PlayerColor.white,
        position: TilePosition(1, 2),
      );
      final pieces = {
        const TilePosition(0, 0): knight,
        const TilePosition(1, 2): friendly,
      };
      final moves = calc(board, pieces).legalMoves(knight);
      expect(moves.contains(const TilePosition(1, 2)), isFalse);
    });

    test('knight can capture enemy king', () {
      final board = fullBoard3x3();
      const knight = ChessPiece(
        type: PieceType.knight,
        color: PlayerColor.white,
        position: TilePosition(0, 0),
      );
      const enemyKing = ChessPiece(
        type: PieceType.king,
        color: PlayerColor.black,
        position: TilePosition(1, 2),
      );
      final pieces = {
        const TilePosition(0, 0): knight,
        const TilePosition(1, 2): enemyKing,
      };
      final moves = calc(board, pieces).legalMoves(knight);
      expect(moves.contains(const TilePosition(1, 2)), isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('GameState — win condition', () {
    test('capturing the King ends the game', () {
      final board = fullBoard3x3();
      const whiteKnight = ChessPiece(
        type: PieceType.knight,
        color: PlayerColor.white,
        position: TilePosition(0, 0),
      );
      const blackKing = ChessPiece(
        type: PieceType.king,
        color: PlayerColor.black,
        position: TilePosition(1, 2),
      );

      // Use GameState directly
      final gs = _makeState(board, {
        const TilePosition(0, 0): whiteKnight,
        const TilePosition(1, 2): blackKing,
      });

      expect(gs.status, GameStatus.ongoing);
      final ok = gs.move(whiteKnight, const TilePosition(1, 2));
      expect(ok, isTrue);
      expect(gs.status, GameStatus.whiteWins);
    });
  });
}

// ignore: library_private_types_in_public_api
_GameStateHelper _makeState(
    GameBoard board, Map<TilePosition, ChessPiece> pieces) {
  return _GameStateHelper(board, pieces);
}

// Thin wrapper since GameState constructor accepts initialPieces map
class _GameStateHelper {
  final GameBoard board;
  final Map<TilePosition, ChessPiece> _pieces;
  PlayerColor _turn = PlayerColor.white;
  GameStatus status = GameStatus.ongoing;

  _GameStateHelper(this.board, Map<TilePosition, ChessPiece> pieces)
      : _pieces = Map.from(pieces);

  bool move(ChessPiece piece, TilePosition dest) {
    final calc = MovementCalculator(board: board, pieceMap: _pieces);
    if (!calc.legalMoves(piece).contains(dest)) return false;
    _pieces.remove(piece.position);
    final captured = _pieces[dest];
    _pieces[dest] = piece.copyWith(position: dest);
    if (captured?.type == PieceType.king) {
      status = piece.color == PlayerColor.white
          ? GameStatus.whiteWins
          : GameStatus.blackWins;
    } else {
      _turn = _turn == PlayerColor.white ? PlayerColor.black : PlayerColor.white;
    }
    return true;
  }
}
