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
///  - A minimum of ~60 normal tiles total is enforced (50 for intenso).
class RandomBoardGenerator {
  RandomBoardGenerator._();

  // ── Normal difficulty patterns ──────────────────────────────────────────

  /// Patterns allowed for corner modules (may have more voids).
  static const _cornerPatterns = [
    ModulePatternType.full,
    ModulePatternType.full,
    ModulePatternType.cornerCut,
    ModulePatternType.cornerCut,
    ModulePatternType.diagonalCut,
    ModulePatternType.lShape,
    ModulePatternType.tShape,
    ModulePatternType.checkerboard,
  ];

  /// Patterns allowed for edge modules (moderate voids).
  static const _edgePatterns = [
    ModulePatternType.full,
    ModulePatternType.full,
    ModulePatternType.full,
    ModulePatternType.cornerCut,
    ModulePatternType.tShape,
    ModulePatternType.diagonalCut,
    ModulePatternType.checkerboard,
  ];

  // ── Intenso difficulty patterns ─────────────────────────────────────────

  /// Corner patterns for intenso mode (more precipices).
  static const _cornerPatternsIntenso = [
    ModulePatternType.cornerCut,
    ModulePatternType.diagonalCut,
    ModulePatternType.lShape,
    ModulePatternType.checkerboard,
    ModulePatternType.tShape,
    ModulePatternType.halfSplit,
  ];

  /// Edge patterns for intenso mode (more precipices).
  static const _edgePatternsIntenso = [
    ModulePatternType.cornerCut,
    ModulePatternType.tShape,
    ModulePatternType.diagonalCut,
    ModulePatternType.checkerboard,
    ModulePatternType.halfSplit,
    ModulePatternType.lShape,
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
    return _buildLayout(
      rng: rng,
      cornerPatterns: _cornerPatterns,
      edgePatterns: _edgePatterns,
      minNormalTiles: 60,
    );
  }

  /// Generate a random [BoardLayout] with intenso difficulty (more precipices).
  static BoardLayout generateIntenso([Random? rng]) {
    return _buildLayout(
      rng: rng,
      cornerPatterns: _cornerPatternsIntenso,
      edgePatterns: _edgePatternsIntenso,
      minNormalTiles: 50,
    );
  }

  static BoardLayout _buildLayout({
    Random? rng,
    required List<ModulePatternType> cornerPatterns,
    required List<ModulePatternType> edgePatterns,
    required int minNormalTiles,
  }) {
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
          pattern = cornerPatterns[r.nextInt(cornerPatterns.length)];
          final key = '$mx,$my';
          rotation = pattern == ModulePatternType.full
              ? 0
              : _cornerRotations[key] ?? r.nextInt(4);
        } else {
          // Edge (non-corner, non-center)
          pattern = edgePatterns[r.nextInt(edgePatterns.length)];
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
    if (normalCount < minNormalTiles) {
      return _buildLayout(
        rng: r,
        cornerPatterns: cornerPatterns,
        edgePatterns: edgePatterns,
        minNormalTiles: minNormalTiles,
      );
    }

    return BoardLayout(
      name: _generateName(r),
      description: '$normalCount casillas · ${81 - normalCount} precipicios',
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
    'PUMA MARCA',
    'RAQCHI',
    'CHAVÍN',
    'CARAL',
    'PACHACAMAC',
    'CHINCHERO',
    'URUBAMBA',
    'CUSCO',
    'HATUN RUMIYOC',
    'QENQO',
  ];

  static String _generateName(Random r) => _names[r.nextInt(_names.length)];
}

/// Predefined layouts, presets, and random generator access.
class BoardLayouts {
  BoardLayouts._();

  // ── Legacy layouts (still available for specific game modes) ──────────────

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

  // ── Curated preset layouts (9 modules in 3×3 grid) ──────────────────────

  /// Cruz Inka — Esquinas cortadas apuntando hacia afuera.
  static const cruzInka = BoardLayout(
    name: 'CRUZ INKA',
    description: 'Esquinas cortadas con precipicios apuntando hacia afuera',
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
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(1, 1),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(2, 1),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(0, 2),
          patternType: ModulePatternType.cornerCut,
          rotationSteps: 3),
      ModulePlacement(
          coordinate: BoardCoordinate(1, 2),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(2, 2),
          patternType: ModulePatternType.cornerCut,
          rotationSteps: 2),
    ],
  );

  /// Laberinto — Diagonales y T alternadas.
  static const laberinto = BoardLayout(
    name: 'LABERINTO',
    description: 'Patrón de diagonales y formas T alternadas',
    modules: [
      ModulePlacement(
          coordinate: BoardCoordinate(0, 0),
          patternType: ModulePatternType.diagonalCut,
          rotationSteps: 0),
      ModulePlacement(
          coordinate: BoardCoordinate(1, 0),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(2, 0),
          patternType: ModulePatternType.diagonalCut,
          rotationSteps: 1),
      ModulePlacement(
          coordinate: BoardCoordinate(0, 1),
          patternType: ModulePatternType.tShape,
          rotationSteps: 1),
      ModulePlacement(
          coordinate: BoardCoordinate(1, 1),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(2, 1),
          patternType: ModulePatternType.tShape,
          rotationSteps: 3),
      ModulePlacement(
          coordinate: BoardCoordinate(0, 2),
          patternType: ModulePatternType.diagonalCut,
          rotationSteps: 3),
      ModulePlacement(
          coordinate: BoardCoordinate(1, 2),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(2, 2),
          patternType: ModulePatternType.diagonalCut,
          rotationSteps: 2),
    ],
  );

  /// Ajedrez Sagrado — Tablero de ajedrez en esquinas y bordes.
  static const ajedrezSagrado = BoardLayout(
    name: 'AJEDREZ SAGRADO',
    description: 'Patrón de ajedrez en todos los módulos laterales',
    modules: [
      ModulePlacement(
          coordinate: BoardCoordinate(0, 0),
          patternType: ModulePatternType.checkerboard,
          rotationSteps: 0),
      ModulePlacement(
          coordinate: BoardCoordinate(1, 0),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(2, 0),
          patternType: ModulePatternType.checkerboard,
          rotationSteps: 0),
      ModulePlacement(
          coordinate: BoardCoordinate(0, 1),
          patternType: ModulePatternType.checkerboard,
          rotationSteps: 0),
      ModulePlacement(
          coordinate: BoardCoordinate(1, 1),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(2, 1),
          patternType: ModulePatternType.checkerboard,
          rotationSteps: 0),
      ModulePlacement(
          coordinate: BoardCoordinate(0, 2),
          patternType: ModulePatternType.checkerboard,
          rotationSteps: 0),
      ModulePlacement(
          coordinate: BoardCoordinate(1, 2),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(2, 2),
          patternType: ModulePatternType.checkerboard,
          rotationSteps: 0),
    ],
  );

  /// Templo — Mitades bloqueadas simétricas (columnas vacías en los lados).
  static const templo = BoardLayout(
    name: 'TEMPLO',
    description: 'Columnas vacías simétricas enmarcando el centro',
    modules: [
      ModulePlacement(
          coordinate: BoardCoordinate(0, 0),
          patternType: ModulePatternType.lShape,
          rotationSteps: 0),
      ModulePlacement(
          coordinate: BoardCoordinate(1, 0),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(2, 0),
          patternType: ModulePatternType.lShape,
          rotationSteps: 2),
      ModulePlacement(
          coordinate: BoardCoordinate(0, 1),
          patternType: ModulePatternType.lShape,
          rotationSteps: 0),
      ModulePlacement(
          coordinate: BoardCoordinate(1, 1),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(2, 1),
          patternType: ModulePatternType.lShape,
          rotationSteps: 2),
      ModulePlacement(
          coordinate: BoardCoordinate(0, 2),
          patternType: ModulePatternType.lShape,
          rotationSteps: 0),
      ModulePlacement(
          coordinate: BoardCoordinate(1, 2),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(2, 2),
          patternType: ModulePatternType.lShape,
          rotationSteps: 2),
    ],
  );

  /// Serpiente — Patrón asimétrico de diagonales cruzadas.
  static const serpiente = BoardLayout(
    name: 'SERPIENTE',
    description: 'Diagonales cruzadas asimétricas serpenteando el tablero',
    modules: [
      ModulePlacement(
          coordinate: BoardCoordinate(0, 0),
          patternType: ModulePatternType.diagonalCut,
          rotationSteps: 0),
      ModulePlacement(
          coordinate: BoardCoordinate(1, 0),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(2, 0),
          patternType: ModulePatternType.lShape,
          rotationSteps: 1),
      ModulePlacement(
          coordinate: BoardCoordinate(0, 1),
          patternType: ModulePatternType.tShape,
          rotationSteps: 0),
      ModulePlacement(
          coordinate: BoardCoordinate(1, 1),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(2, 1),
          patternType: ModulePatternType.tShape,
          rotationSteps: 2),
      ModulePlacement(
          coordinate: BoardCoordinate(0, 2),
          patternType: ModulePatternType.lShape,
          rotationSteps: 3),
      ModulePlacement(
          coordinate: BoardCoordinate(1, 2),
          patternType: ModulePatternType.full),
      ModulePlacement(
          coordinate: BoardCoordinate(2, 2),
          patternType: ModulePatternType.diagonalCut,
          rotationSteps: 2),
    ],
  );

  /// All legacy layouts.
  static const List<BoardLayout> legacy = [clasico];

  /// All curated preset layouts (including clásico).
  static const List<BoardLayout> preset = [
    clasico,
    cruzInka,
    laberinto,
    ajedrezSagrado,
    templo,
    serpiente,
  ];

  /// Generate a random 3×3 (9-module) board with precipices.
  /// This is the default for new games.
  static BoardLayout random([Random? rng]) =>
      RandomBoardGenerator.generate(rng);

  /// Generate a random 3×3 board with intenso difficulty (more precipices).
  static BoardLayout randomIntenso([Random? rng]) =>
      RandomBoardGenerator.generateIntenso(rng);
}
