/// A single cell inside a ChessModule.
/// [TileType.normal]  → playable square
/// [TileType.void_]   → impassable hole in the board
enum TileType { normal, void_ }

class Tile {
  final TileType type;
  const Tile(this.type);

  bool get isNormal => type == TileType.normal;
  bool get isVoid   => type == TileType.void_;

  Tile copyWith({TileType? type}) => Tile(type ?? this.type);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Tile && other.type == type);

  @override
  int get hashCode => type.hashCode;

  @override
  String toString() => isNormal ? '■' : '□';
}
