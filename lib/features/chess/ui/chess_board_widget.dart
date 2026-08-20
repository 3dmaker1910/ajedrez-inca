import 'package:flutter/material.dart';
import '../board/game_board.dart';
import '../models/board_coordinate.dart';
import '../pieces/chess_piece.dart';
import '../pieces/movement_calculator.dart';
import 'board_painter.dart';
import 'chess_colors.dart';

/// Interactive board widget \u2014 handles tap events and delegates painting
/// to [BoardPainter]. Supports module gaps for visual separation.
class ChessBoardWidget extends StatefulWidget {
  final GameBoard board;
  final Map<TilePosition, ChessPiece> pieces;
  final PlayerColor currentTurn;
  final double tileSize;
  final void Function(ChessPiece piece, TilePosition destination)? onMove;

  const ChessBoardWidget({
    super.key,
    required this.board,
    required this.pieces,
    required this.currentTurn,
    this.tileSize = 48,
    this.onMove,
  });

  @override
  State<ChessBoardWidget> createState() => _ChessBoardWidgetState();
}

class _ChessBoardWidgetState extends State<ChessBoardWidget> {
  TilePosition? _selected;
  List<TilePosition> _possibleMoves = [];

  @override
  Widget build(BuildContext context) {
    final b = widget.board.bounds;
    if (b == null) {
      return const Center(
        child: Text(
          'Place a module to start',
          style: TextStyle(color: ChessColors.gold),
        ),
      );
    }

    final canvasSize = BoardPainter.totalSize(widget.board, widget.tileSize);

    return GestureDetector(
      onTapDown: (details) => _handleTap(details.localPosition),
      child: CustomPaint(
        painter: BoardPainter(
          board: widget.board,
          pieces: widget.pieces,
          selectedTile: _selected,
          possibleMoves: _possibleMoves,
          tileSize: widget.tileSize,
        ),
        size: canvasSize,
      ),
    );
  }

  void _handleTap(Offset local) {
    final tapped = BoardPainter.pixelToTile(local, widget.board, widget.tileSize);
    if (tapped == null) {
      setState(() { _selected = null; _possibleMoves = []; });
      return;
    }

    if (!widget.board.isNormalTile(tapped)) {
      setState(() { _selected = null; _possibleMoves = []; });
      return;
    }

    if (_selected != null && _possibleMoves.contains(tapped)) {
      // Execute move
      final piece = widget.pieces[_selected!]!;
      widget.onMove?.call(piece, tapped);
      setState(() { _selected = null; _possibleMoves = []; });
      return;
    }

    final piece = widget.pieces[tapped];
    if (piece != null && piece.color == widget.currentTurn) {
      final calc = MovementCalculator(
        board: widget.board,
        pieceMap: widget.pieces,
      );
      setState(() {
        _selected     = tapped;
        _possibleMoves = calc.legalMoves(piece);
      });
    } else {
      setState(() { _selected = null; _possibleMoves = []; });
    }
  }
}
