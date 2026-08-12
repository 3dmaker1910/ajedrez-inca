import '../models/board_coordinate.dart';

/// All piece types in Viracocha Chess.
enum PieceType { king, rook, bishop, knight }

/// Player side.
enum PlayerColor { white, black }

/// An immutable chess piece placed at a [position].
class ChessPiece {
  final PieceType type;
  final PlayerColor color;
  final TilePosition position;

  const ChessPiece({
    required this.type,
    required this.color,
    required this.position,
  });

  ChessPiece copyWith({TilePosition? position}) => ChessPiece(
        type: type,
        color: color,
        position: position ?? this.position,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChessPiece &&
          other.type == type &&
          other.color == color &&
          other.position == position);

  @override
  int get hashCode => Object.hash(type, color, position);

  @override
  String toString() =>
      '${color.name[0].toUpperCase()}${type.name[0].toUpperCase()}@$position';
}
