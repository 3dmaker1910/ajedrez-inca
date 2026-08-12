/// 2-D coordinate for module placement on the [GameBoard].
class BoardCoordinate {
  final int x;
  final int y;

  const BoardCoordinate(this.x, this.y);

  BoardCoordinate operator +(BoardCoordinate other) =>
      BoardCoordinate(x + other.x, y + other.y);

  BoardCoordinate operator -(BoardCoordinate other) =>
      BoardCoordinate(x - other.x, y - other.y);

  List<BoardCoordinate> get adjacentModules => [
        BoardCoordinate(x, y - 1), // top
        BoardCoordinate(x + 1, y), // right
        BoardCoordinate(x, y + 1), // bottom
        BoardCoordinate(x - 1, y), // left
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoardCoordinate && other.x == x && other.y == y);

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x,$y)';
}

/// A world-space tile position (absolute row/col across the full board).
class TilePosition {
  final int row;
  final int col;

  const TilePosition(this.row, this.col);

  TilePosition operator +(TilePosition other) =>
      TilePosition(row + other.row, col + other.col);

  TilePosition step(Direction dir) {
    switch (dir) {
      case Direction.up:    return TilePosition(row - 1, col);
      case Direction.down:  return TilePosition(row + 1, col);
      case Direction.left:  return TilePosition(row, col - 1);
      case Direction.right: return TilePosition(row, col + 1);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TilePosition && other.row == row && other.col == col);

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => '[r$row,c$col]';
}

enum Direction { up, down, left, right }
