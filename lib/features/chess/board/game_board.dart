import '../models/board_coordinate.dart';
import '../models/chess_module.dart';
import '../models/tile.dart';

/// The dynamic game board made of [ChessModule]s placed on a coordinate grid.
/// Modules must be connected (share at least one edge with an existing module).
class GameBoard {
  final Map<BoardCoordinate, ChessModule> _modules = {};

  /// World tile (row, col) origin = top-left of the bounding rect of all modules.
  /// Module at (mx, my) occupies world rows [my*3 .. my*3+2], cols [mx*3 .. mx*3+2].

  // ─── Module Placement ──────────────────────────────────────────────────────

  /// Place the first module (no connectivity check needed).
  bool placeFirstModule(ChessModule module, [BoardCoordinate? at]) {
    if (_modules.isNotEmpty) return false;
    _modules[at ?? const BoardCoordinate(0, 0)] = module;
    return true;
  }

  /// Place [module] at [coord].
  /// Returns `true` on success, `false` if the position is taken or disconnected.
  bool placeModule(ChessModule module, BoardCoordinate coord) {
    if (_modules.containsKey(coord)) return false;
    if (_modules.isEmpty) {
      _modules[coord] = module;
      return true;
    }
    if (!_isConnected(coord)) return false;
    _modules[coord] = module;
    return true;
  }

  /// Remove module at [coord]. Returns the removed module or null.
  ChessModule? removeModule(BoardCoordinate coord) => _modules.remove(coord);

  bool get isEmpty => _modules.isEmpty;
  int  get moduleCount => _modules.length;

  Map<BoardCoordinate, ChessModule> get modules => Map.unmodifiable(_modules);

  // ─── Connectivity ──────────────────────────────────────────────────────────

  bool _isConnected(BoardCoordinate coord) =>
      coord.adjacentModules.any((adj) => _modules.containsKey(adj));

  /// Returns true if all placed modules form one connected component.
  bool get isFullyConnected {
    if (_modules.isEmpty) return true;
    final visited = <BoardCoordinate>{};
    final queue   = [_modules.keys.first];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      if (visited.contains(current)) continue;
      visited.add(current);
      for (final adj in current.adjacentModules) {
        if (_modules.containsKey(adj) && !visited.contains(adj)) {
          queue.add(adj);
        }
      }
    }
    return visited.length == _modules.length;
  }

  // ─── Tile Lookup ───────────────────────────────────────────────────────────

  /// Returns the [Tile] at absolute world position [pos], or `null` if out of bounds.
  Tile? tileAt(TilePosition pos) {
    final moduleCoord = _moduleCoordForTile(pos);
    final module = _modules[moduleCoord];
    if (module == null) return null;
    final localRow = pos.row - moduleCoord.y * 3;
    final localCol = pos.col - moduleCoord.x * 3;
    if (localRow < 0 || localRow > 2 || localCol < 0 || localCol > 2) return null;
    return module.tileAt(localRow, localCol);
  }

  bool isNormalTile(TilePosition pos) => tileAt(pos)?.isNormal ?? false;
  bool isVoidTile(TilePosition pos)   => tileAt(pos)?.isVoid   ?? false;
  bool isOnBoard(TilePosition pos)    => tileAt(pos) != null;

  BoardCoordinate _moduleCoordForTile(TilePosition pos) {
    int mx = pos.col >= 0
        ? pos.col ~/ 3
        : (pos.col - 2) ~/ 3; // floor division for negatives
    int my = pos.row >= 0
        ? pos.row ~/ 3
        : (pos.row - 2) ~/ 3;
    return BoardCoordinate(mx, my);
  }

  // ─── Bounds ────────────────────────────────────────────────────────────────

  /// Bounding box of all world tiles (inclusive).
  ({int minRow, int maxRow, int minCol, int maxCol})? get bounds {
    if (_modules.isEmpty) return null;
    int minX = double.maxFinite.toInt();
    int maxX = -double.maxFinite.toInt();
    int minY = double.maxFinite.toInt();
    int maxY = -double.maxFinite.toInt();
    for (final coord in _modules.keys) {
      if (coord.x < minX) minX = coord.x;
      if (coord.x > maxX) maxX = coord.x;
      if (coord.y < minY) minY = coord.y;
      if (coord.y > maxY) maxY = coord.y;
    }
    return (
      minRow: minY * 3,
      maxRow: maxY * 3 + 2,
      minCol: minX * 3,
      maxCol: maxX * 3 + 2,
    );
  }

  @override
  String toString() {
    final b = bounds;
    if (b == null) return 'GameBoard(empty)';
    final sb = StringBuffer('GameBoard(${moduleCount} modules)\n');
    for (int r = b.minRow; r <= b.maxRow; r++) {
      for (int c = b.minCol; c <= b.maxCol; c++) {
        final tile = tileAt(TilePosition(r, c));
        sb.write(tile == null ? ' ' : tile.toString());
        if ((c + 1 - b.minCol) % 3 == 0 && c < b.maxCol) sb.write('|');
      }
      if ((r + 1 - b.minRow) % 3 == 0 && r < b.maxRow) {
        sb.write('\n');
        sb.write('-' * ((b.maxCol - b.minCol + 1) + (moduleCount - 1)));
      }
      sb.write('\n');
    }
    return sb.toString();
  }
}
