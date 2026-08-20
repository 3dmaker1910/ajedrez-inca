import 'dart:math';
import '../models/board_coordinate.dart';
import '../models/chess_module.dart';
import '../models/module_pattern.dart';
import '../models/tile.dart';
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

// ─────────────────────────────────────────────────────────────────────────────
// Random 3×3 (9-module) board generator
// ─────────────────────────────────────────────────────────────────────────────

/// Generates a random 3×3 grid of 9 modules with precipices (voids).
/// Rules for a fair game:
///  - The top and bottom rows (y=0 and y=2) always have their center module
///    (x=1) full, guaranteeing >= 9 tiles in the starting rows for pieces.
///  - Edge modules (not center) get a random pattern with 0-2 rotations.
///  - The center module (1,1) is always full.
///  - Corner modules may get heavier void patterns.
///  - A minimum of ~60 normal tiles total is enforced.
class RandomBoardGenerator {
  RandomBoardGenerator._();

  /// Patterns allowed for corner modules (may have more voids).
  static const _cornerPatterns = [
    ModulePatternType.full,
    ModulePatternType.full,
    ModulePatternType.cornerCut,
    ModulePatternType.cornerCut,
    ModulePatternType.diagonalCut,
    ModulePatternType.lShape,
  ];

  /// Patterns allowed for edge modules (moderate voids).
  static const _edgePatterns = [
    ModulePatternType.full,
    ModulePatternType.full,
    ModulePatternType.full,
    ModulePatternType.cornerCut,
    ModulePatternType.tShape,
  ];

  /// Preferred rotation for corner modules to point voids outward.
  /// Maps (mx, my) to recommended rotation steps for cornerCut.
  static const _cornerRotations = {
    '0,0': 0, // top-left corner void at top-left
    '2,0': 1, // top-right corner void at top-right
    '0,2': 3, // bottom-left corner void at bottom-left
    '2,2': 2, // bottom-right corner void at bottom-right
  };

  /// Generate a random [BoardLayout] with 9 modules in a 3×3 grid.
  static BoardLayout generate([Random? rng]) {
    final r = rng ?? Random();
    final placements = <ModulePlacement>[];

    for (int my = 0; my < 3; my++) {
      for (int mx = 0; mx < 3; mx++) {
        final isCenter = mx == 1 && my == 1;
        final isCorner = (mx == 0 || mx == 2) && (my == 0 || my == 2);
        final isTopBottomCenter = mx == 1 && (my == 0 || my == 2);

        ModulePatternType pattern;
        int rotation;

        if (isCenter || isTopBottomCenter) {
          // Center and top/bottom center always full for piece placement
          pattern = ModulePatternType.full;
          rotation = 0;
        } else if (isCorner) {
          pattern = _cornerPatterns[r.nextInt(_cornerPatterns.length)];
          final key = '$mx,$my';
          rotation = pattern == ModulePatternType.full
              ? 0
              : _cornerRotations[key] ?? r.nextInt(4);
        } else {
          // Edge (non-corner, non-center)
          pattern = _edgePatterns[r.nextInt(_edgePatterns.length)];
          rotation = r.nextInt(4);
        }

        placements.add(ModulePlacement(
          coordinate: BoardCoordinate(mx, my),
          patternType: pattern,
          rotationSteps: rotation,
        ));
      }
    }

    // Count normal tiles; if too few, retry (rare)
    int normalCount = 0;
    for (final p in placements) {
      final m = ChessModule(patternType: p.patternType)
          .rotateClockwiseN(p.rotationSteps);
      normalCount += m.normalTileCount;
    }
    if (normalCount < 60) {
      return generate(r); // Retry
    }

    return BoardLayout(
      name: _generateName(r),
      description: '$normalCount casillas \u00b7 ${81 - normalCount} precipicios',
      modules: placements,
    );
  }

  static const _names = [
    'TIAWANAKU',
    'SACSAYWAMAN',
    'QORICANCHA',
    'MACHUPICCHU',
    'OLLANTAYTAMBO',
    'VILCABAMBA',
    'CHOQUEQUIRAO',
    'PISAC',
    'MORAY',
    'TAMBOMACHAY',
    'HUAYNA PICCHU',
    'INTI RAYMI',
  ];

  static String _generateName(Random r) => _names[r.nextInt(_names.length)];
}

/// Legacy predefined layouts + random generator access.
class BoardLayouts {
  BoardLayouts._();

  // ── Legacy layouts (still available for specific game modes) ──────────────

  static const clasico = BoardLayout(
    name: 'CL\u00c1SICO',
    description: 'Tablero est\u00e1ndar 9×6, sin precipicios',
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

  /// All legacy layouts.
  static const List<BoardLayout> legacy = [clasico];

  /// Generate a random 3×3 (9-module) board with precipices.
  /// This is the default for new games.
  static BoardLayout random([Random? rng]) =>
      RandomBoardGenerator.generate(rng);
}
