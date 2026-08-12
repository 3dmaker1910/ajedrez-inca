import 'package:test/test.dart';
import 'package:viracocha_chess/features/chess/models/board_coordinate.dart';
import 'package:viracocha_chess/features/chess/models/chess_module.dart';
import 'package:viracocha_chess/features/chess/models/module_pattern.dart';
import 'package:viracocha_chess/features/chess/board/game_board.dart';

void main() {
  GameBoard makeBoard() => GameBoard();

  group('GameBoard — placement', () {
    test('first module is placed without connectivity check', () {
      final board = makeBoard();
      final module = ChessModule(patternType: ModulePatternType.full);
      expect(board.placeFirstModule(module), isTrue);
      expect(board.moduleCount, 1);
    });

    test('cannot place a second module with placeFirstModule', () {
      final board = makeBoard();
      board.placeFirstModule(ChessModule(patternType: ModulePatternType.full));
      expect(
        board.placeFirstModule(ChessModule(patternType: ModulePatternType.full)),
        isFalse,
      );
      expect(board.moduleCount, 1);
    });

    test('adjacent placement succeeds', () {
      final board = makeBoard();
      board.placeFirstModule(ChessModule(patternType: ModulePatternType.full));
      final ok = board.placeModule(
        ChessModule(patternType: ModulePatternType.cornerCut),
        const BoardCoordinate(1, 0),
      );
      expect(ok, isTrue);
      expect(board.moduleCount, 2);
    });

    test('disconnected placement fails', () {
      final board = makeBoard();
      board.placeFirstModule(ChessModule(patternType: ModulePatternType.full));
      final ok = board.placeModule(
        ChessModule(patternType: ModulePatternType.full),
        const BoardCoordinate(5, 5), // far away
      );
      expect(ok, isFalse);
      expect(board.moduleCount, 1);
    });

    test('duplicate position rejected', () {
      final board = makeBoard();
      board.placeFirstModule(ChessModule(patternType: ModulePatternType.full));
      final dup = board.placeModule(
        ChessModule(patternType: ModulePatternType.full),
        const BoardCoordinate(0, 0),
      );
      expect(dup, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('GameBoard — connectivity', () {
    test('single module is fully connected', () {
      final board = makeBoard();
      board.placeFirstModule(ChessModule(patternType: ModulePatternType.full));
      expect(board.isFullyConnected, isTrue);
    });

    test('two adjacent modules are fully connected', () {
      final board = makeBoard();
      board.placeFirstModule(ChessModule(patternType: ModulePatternType.full));
      board.placeModule(
        ChessModule(patternType: ModulePatternType.full),
        const BoardCoordinate(1, 0),
      );
      expect(board.isFullyConnected, isTrue);
    });

    test('empty board is fully connected', () {
      expect(makeBoard().isFullyConnected, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('GameBoard — tile lookup', () {
    late GameBoard board;
    setUp(() {
      board = makeBoard();
      // full module at (0,0) → world rows 0-2, cols 0-2, all normal
      board.placeFirstModule(
        ChessModule(patternType: ModulePatternType.full),
        const BoardCoordinate(0, 0),
      );
      // cornerCut at (1,0) → world rows 0-2, cols 3-5
      // tileAt(0,0) of module = void
      board.placeModule(
        ChessModule(patternType: ModulePatternType.cornerCut),
        const BoardCoordinate(1, 0),
      );
    });

    test('world tile from full module is normal', () {
      expect(board.isNormalTile(const TilePosition(0, 0)), isTrue);
      expect(board.isNormalTile(const TilePosition(2, 2)), isTrue);
    });

    test('world tile outside any module returns null', () {
      expect(board.tileAt(const TilePosition(10, 10)), isNull);
    });

    test('cornerCut module has void at world row 0, col 3', () {
      expect(board.isVoidTile(const TilePosition(0, 3)), isTrue);
    });

    test('cornerCut module has normal at world row 0, col 4', () {
      expect(board.isNormalTile(const TilePosition(0, 4)), isTrue);
    });

    test('isOnBoard returns false for gaps', () {
      expect(board.isOnBoard(const TilePosition(0, 100)), isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('GameBoard — bounds', () {
    test('bounds of single module at origin', () {
      final board = makeBoard();
      board.placeFirstModule(ChessModule(patternType: ModulePatternType.full));
      final b = board.bounds;
      expect(b, isNotNull);
      expect(b!.minRow, 0);
      expect(b.maxRow, 2);
      expect(b.minCol, 0);
      expect(b.maxCol, 2);
    });

    test('bounds expand with second module', () {
      final board = makeBoard();
      board.placeFirstModule(ChessModule(patternType: ModulePatternType.full));
      board.placeModule(
        ChessModule(patternType: ModulePatternType.full),
        const BoardCoordinate(0, 1), // directly below
      );
      final b = board.bounds!;
      expect(b.minRow, 0);
      expect(b.maxRow, 5); // 2 modules high
      expect(b.minCol, 0);
      expect(b.maxCol, 2);
    });

    test('empty board has null bounds', () {
      expect(makeBoard().bounds, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('GameBoard — removal', () {
    test('remove returns the module and decrements count', () {
      final board = makeBoard();
      board.placeFirstModule(
        ChessModule(patternType: ModulePatternType.full),
        const BoardCoordinate(0, 0),
      );
      final removed = board.removeModule(const BoardCoordinate(0, 0));
      expect(removed, isNotNull);
      expect(board.moduleCount, 0);
    });

    test('remove non-existent returns null', () {
      final board = makeBoard();
      expect(board.removeModule(const BoardCoordinate(99, 99)), isNull);
    });
  });
}
