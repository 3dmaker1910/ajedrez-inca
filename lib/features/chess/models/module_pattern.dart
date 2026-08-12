import 'tile.dart';

const Tile N = Tile(TileType.normal);
const Tile V = Tile(TileType.void_);

/// The 9 canonical 3x3 module patterns.
/// Each list is row-major: [row0col0, row0col1, row0col2, row1col0, …]
enum ModulePatternType {
  full,        // all 9 normal
  cornerCut,   // one corner void
  diagonalCut, // two diagonal corners void
  lShape,      // L-shaped void cluster
  tShape,      // T-shaped center row
  crossVoid,   // center cross void
  ringVoid,    // ring of voids (only center normal)
  halfSplit,   // left column void
  checkerboard // checkerboard pattern
}

class ModulePattern {
  final ModulePatternType type;
  final List<List<Tile>> grid; // 3×3

  const ModulePattern._(this.type, this.grid);

  static ModulePattern forType(ModulePatternType type) {
    switch (type) {
      case ModulePatternType.full:
        return ModulePattern._(type, [
          [N, N, N],
          [N, N, N],
          [N, N, N],
        ]);
      case ModulePatternType.cornerCut:
        return ModulePattern._(type, [
          [V, N, N],
          [N, N, N],
          [N, N, N],
        ]);
      case ModulePatternType.diagonalCut:
        return ModulePattern._(type, [
          [V, N, N],
          [N, N, N],
          [N, N, V],
        ]);
      case ModulePatternType.lShape:
        return ModulePattern._(type, [
          [N, N, V],
          [N, N, V],
          [N, N, V],
        ]);
      case ModulePatternType.tShape:
        return ModulePattern._(type, [
          [N, V, N],
          [N, V, N],
          [N, N, N],
        ]);
      case ModulePatternType.crossVoid:
        return ModulePattern._(type, [
          [N, V, N],
          [V, V, V],
          [N, V, N],
        ]);
      case ModulePatternType.ringVoid:
        return ModulePattern._(type, [
          [V, V, V],
          [V, N, V],
          [V, V, V],
        ]);
      case ModulePatternType.halfSplit:
        return ModulePattern._(type, [
          [V, V, N],
          [V, V, N],
          [V, V, N],
        ]);
      case ModulePatternType.checkerboard:
        return ModulePattern._(type, [
          [N, V, N],
          [V, N, V],
          [N, V, N],
        ]);
    }
  }
}
