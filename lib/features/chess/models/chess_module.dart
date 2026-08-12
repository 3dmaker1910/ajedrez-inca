import 'tile.dart';
import 'module_pattern.dart';

/// A 3×3 grid of [Tile]s that forms one module on the board.
/// Modules can be rotated clockwise in 90° steps.
class ChessModule {
  final ModulePatternType patternType;
  final List<List<Tile>> _grid; // mutable internal state (deep copy on rotate)
  final int rotation; // 0, 90, 180, 270

  ChessModule({
    required this.patternType,
    List<List<Tile>>? grid,
    this.rotation = 0,
  }) : _grid = grid ??
            ModulePattern.forType(patternType)
                .grid
                .map((row) => List<Tile>.from(row))
                .toList();

  /// Returns the tile at [row], [col] (0-indexed, within 0..2).
  Tile tileAt(int row, int col) => _grid[row][col];

  /// Read-only view of the grid rows.
  List<List<Tile>> get grid =>
      List.unmodifiable(_grid.map((r) => List.unmodifiable(r)));

  /// Returns a NEW ChessModule rotated 90° clockwise.
  /// Rotation formula: newGrid[col][2-row] = oldGrid[row][col]
  ChessModule rotateClockwise() {
    final newGrid = List.generate(
      3,
      (_) => List<Tile>.filled(3, const Tile(TileType.normal)),
    );
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        newGrid[c][2 - r] = _grid[r][c];
      }
    }
    return ChessModule(
      patternType: patternType,
      grid: newGrid,
      rotation: (rotation + 90) % 360,
    );
  }

  /// Returns a NEW ChessModule rotated [steps]×90° clockwise.
  ChessModule rotateClockwiseN(int steps) {
    ChessModule result = this;
    for (int i = 0; i < steps % 4; i++) {
      result = result.rotateClockwise();
    }
    return result;
  }

  /// How many normal (playable) tiles this module contains.
  int get normalTileCount =>
      _grid.expand((r) => r).where((t) => t.isNormal).length;

  /// How many void tiles this module contains.
  int get voidTileCount =>
      _grid.expand((r) => r).where((t) => t.isVoid).length;

  @override
  String toString() {
    final sb = StringBuffer('ChessModule($patternType, rot=$rotation°)\n');
    for (final row in _grid) {
      sb.writeln(row.map((t) => t.toString()).join(' '));
    }
    return sb.toString();
  }
}
