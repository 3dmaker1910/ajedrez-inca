import 'dart:math';
import '../models/board_coordinate.dart';
import '../models/chess_module.dart';
import '../models/module_pattern.dart';
import '../pieces/chess_piece.dart';
import 'game_board.dart';

/// Describes a single module to be placed on the board.
class ModulePlacement {
  final BoardCoordinate coordinate;
  final ModulePatternType patternType;
  final int rotationSteps; // 0-3

  const ModulePlacement({
    required this.coordinate,
    required this.patternType,
    this.rotationSteps = 0,
  });
}

/// A named board layout with module placements and piece starting logic.
class BoardLayout {
  final String name;
  final String description;
  final List<ModulePlacement> modules;

  const BoardLayout({
    required this.name,
    required this.description,
    required this.modules,
  });

  /// Apply this layout to a [GameBoard], placing all modules in order.
  void applyTo(GameBoard board) {
    if (modules.isEmpty) return;
    final first = modules.first;
    final firstModule = ChessModule(patternType: first.patternType)
        .rotateClockwiseN(first.rotationSteps);
    board.placeFirstModule(firstModule, first.coordinate);

    for (int i = 1; i < modules.length; i++) {
      final mp = modules[i];
      final module = ChessModule(patternType: mp.patternType)
          .rotateClockwiseN(mp.rotationSteps);
      board.placeModule(module, mp.coordinate);
    }
  }

  /// Find valid starting positions for pieces.
  /// Returns (whitePositions, blackPositions) each with up to 7 TilePositions.
  /// White occupies the bottommost available row, black the topmost.
  (List<TilePosition>, List<TilePosition>) findStartingPositions(
      GameBoard board) {
    final bounds = board.bounds;
    if (bounds == null) return ([], []);

    // Find topmost row with >= 7 normal tiles for black
    List<TilePosition> blackPositions = [];
    for (int r = bounds.minRow; r <= bounds.maxRow; r++) {
      final normalTiles = <TilePosition>[];
      for (int c = bounds.minCol; c <= bounds.maxCol; c++) {
        final pos = TilePosition(r, c);
        if (board.isNormalTile(pos)) {
          normalTiles.add(pos);
        }
      }
      if (normalTiles.length >= 7) {
        // Center the 7 pieces within available tiles
        final start = (normalTiles.length - 7) ~/ 2;
        blackPositions = normalTiles.sublist(start, start + 7);
        break;
      }
    }

    // Find bottommost row with >= 7 normal tiles for white
    List<TilePosition> whitePositions = [];
    for (int r = bounds.maxRow; r >= bounds.minRow; r--) {
      final normalTiles = <TilePosition>[];
      for (int c = bounds.minCol; c <= bounds.maxCol; c++) {
        final pos = TilePosition(r, c);
        if (board.isNormalTile(pos)) {
          normalTiles.add(pos);
        }
      }
      if (normalTiles.length >= 7) {
        final start = (normalTiles.length - 7) ~/ 2;
        whitePositions = normalTiles.sublist(start, start + 7);
        break;
      }
    }

    return (whitePositions, blackPositions);
  }
}

/// The 4 predefined board layouts for random selection at game start.
class BoardLayouts {
  BoardLayouts._();

  // ─────────────────────────────────────────────────────────────────────────
  // 1. CLÁSICO — Standard 3×2 all-full board (9 cols × 6 rows)
  // ─────────────────────────────────────────────────────────────────────────
  static const clasico = BoardLayout(
    name: 'CLÁSICO',
    description: 'Tablero estándar 9×6, sin precipicios',
    modules: [
      ModulePlacement(
          coordinate: BoardCoordinate(0, 0),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(1, 0),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(2, 0),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(0, 1),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(1, 1),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(2, 1),
          patternType: ModulePatternType.full),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────────
  // 2. DOS ISLAS — Two full islands connected by crossVoid bridge modules
  //    Layout: [full][crossVoid][full] × 2 rows
  //    Creates two 3×6 playable islands with only corner-tile crossings
  // ─────────────────────────────────────────────────────────────────────────
  static const dosIslas = BoardLayout(
    name: 'DOS ISLAS',
    description: 'Dos islas conectadas por puentes angostos',
    modules: [
      ModulePlacement(
          coordinate: BoardCoordinate(0, 0),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(1, 0),
          patternType: ModulePatternType.crossVoid),
      ModulePlacement(
          coordinate: BoardCoordinate(2, 0),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(0, 1),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(1, 1),
          patternType: ModulePatternType.crossVoid),
      ModulePlacement(
          coordinate: BoardCoordinate(2, 1),
          patternType: ModulePatternType.full),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────────
  // 3. CHAKANA — Inca cross / hourglass: two wide platforms (9 cols)
  //    connected by a narrow 3-tile bridge through the center module.
  //    Layout:
  //       [0,0][1,0][2,0]   ← top platform (rows 0-2)
  //            [1,1]        ← narrow bridge (rows 3-5)
  //       [0,2][1,2][2,2]   ← bottom platform (rows 6-8)
  // ─────────────────────────────────────────────────────────────────────────
  static const chakana = BoardLayout(
    name: 'CHAKANA',
    description: 'Cruz andina — dos plataformas con puente central',
    modules: [
      ModulePlacement(
          coordinate: BoardCoordinate(0, 0),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(1, 0),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(2, 0),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(1, 1),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(1, 2),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(0, 2),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(2, 2),
          patternType: ModulePatternType.full),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────────
  // 4. FORTALEZA — Fortress with corner-cut modules on all 4 corners.
  //    Creates an octagonal playable area (7 tiles in edge rows).
  //    Layout: [cornerCut r0][full][cornerCut r1]
  //            [cornerCut r3][full][cornerCut r2]
  // ─────────────────────────────────────────────────────────────────────────
  static const fortaleza = BoardLayout(
    name: 'FORTALEZA',
    description: 'Fortaleza octagonal — esquinas al precipicio',
    modules: [
      ModulePlacement(
          coordinate: BoardCoordinate(0, 0),
          patternType: ModulePatternType.cornerCut,
          rotationSteps: 0),
      ModulePlacement(
          coordinate: BoardCoordinate(1, 0),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(2, 0),
          patternType: ModulePatternType.cornerCut,
          rotationSteps: 1),
      ModulePlacement(
          coordinate: BoardCoordinate(0, 1),
          patternType: ModulePatternType.cornerCut,
          rotationSteps: 3),
      ModulePlacement(
          coordinate: BoardCoordinate(1, 1),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(2, 1),
          patternType: ModulePatternType.cornerCut,
          rotationSteps: 2),
    ],
  );

  /// All available layouts.
  static const List<BoardLayout> all = [clasico, dosIslas, chakana, fortaleza];

  /// Pick a random layout.
  static BoardLayout random([Random? rng]) {
    final r = rng ?? Random();
    return all[r.nextInt(all.length)];
  }
}
