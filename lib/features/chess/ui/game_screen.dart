import 'dart:math';
import 'package:flutter/material.dart';
import '../ai/simple_ai.dart';
import '../board/game_board.dart';
import '../board/board_layouts.dart';
import '../models/board_coordinate.dart';
import '../models/chess_module.dart';
import '../models/module_pattern.dart';
import '../pieces/chess_piece.dart';
import '../pieces/game_state.dart';
import 'chess_board_widget.dart';
import 'chess_colors.dart';
import '../models/game_mode.dart';

/// Main game screen — assembles board + status bar.
/// The board is now a fixed 3×3 grid (9 modules) with random precipices,
/// generated automatically at game start.
class GameScreen extends StatefulWidget {
  final GameMode gameMode;

  const GameScreen({super.key, required this.gameMode});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameBoard    _board;
  late GameState    _gameState;
  late BoardLayout  _currentLayout;
  String            _statusMsg       = 'Generando tablero...';
  final SimpleAI    _ai = SimpleAI();
  bool              _aiThinking = false;
  final Random      _rng = Random();
  int _normalTileCount = 0;
  int _voidTileCount   = 0;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    _board = GameBoard();

    // Generate a random 3×3 (9-module) board with precipices
    _currentLayout = BoardLayouts.random(_rng);

    // Apply the layout (places all 9 modules on the board)
    _currentLayout.applyTo(_board);

    // Asignar exactamente 2 Precipicios Sagrados aleatorios por módulo
    _board.randomizePrecipicios(2, _rng);

    // Contar casillas reales post-randomización
    _normalTileCount = 0;
    _voidTileCount   = 0;
    final bds = _board.bounds;
    if (bds != null) {
      for (int r = bds.minRow; r <= bds.maxRow; r++) {
        for (int c = bds.minCol; c <= bds.maxCol; c++) {
          final tile = _board.tileAt(TilePosition(r, c));
          if (tile == null) continue;
          if (tile.isNormal) _normalTileCount++;
          else _voidTileCount++;
        }
      }
    }

    _gameState = GameState(board: _board);

    // Find valid starting positions for pieces
    final (whitePositions, blackPositions) =
        _currentLayout.findStartingPositions(_board);

    // Piece order: Rook, Knight, Bishop, King, Bishop, Knight, Rook
    const pieceOrder = [
      PieceType.rook,
      PieceType.knight,
      PieceType.bishop,
      PieceType.king,
      PieceType.bishop,
      PieceType.knight,
      PieceType.rook,
    ];

    // Place white pieces (bottom)
    for (int i = 0; i < 7 && i < whitePositions.length; i++) {
      _gameState.addPiece(ChessPiece(
        type: pieceOrder[i],
        color: PlayerColor.white,
        position: whitePositions[i],
      ));
    }

    // Place black pieces (top)
    for (int i = 0; i < 7 && i < blackPositions.length; i++) {
      _gameState.addPiece(ChessPiece(
        type: pieceOrder[i],
        color: PlayerColor.black,
        position: blackPositions[i],
      ));
    }

    _aiThinking = false;
    _statusMsg = '♟ Turno de las Blancas  ·  ${_currentLayout.name}';
  }

  @override
  Widget build(BuildContext context) {
    final modeLabel = widget.gameMode == GameMode.vsComputer
        ? 'vs Computadora'
        : '2 Jugadores';

    return Scaffold(
      backgroundColor: ChessColors.background,
      appBar: AppBar(
        backgroundColor: ChessColors.deepPurple,
        title: Text(
          'VIRACOCHA CHESS  ·  $modeLabel',
          style: const TextStyle(
            color: ChessColors.gold,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 14,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: ChessColors.gold),
            tooltip: 'Nueva partida (nuevo tablero)',
            onPressed: () => setState(_initGame),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Status bar ──────────────────────────────────────────────────────────────────
          _StatusBar(
            message: _statusMsg,
            status: _gameState.status,
            aiThinking: _aiThinking,
          ),

          // ── Layout info chip ──────────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            color: ChessColors.deepPurple.withOpacity(0.8),
            child: Row(
              children: [
                const Icon(Icons.grid_view, color: ChessColors.gold, size: 14),
                const SizedBox(width: 6),
                Text(
                  '${_currentLayout.name} — $_normalTileCount casillas · $_voidTileCount precipicios',
                  style: TextStyle(
                    color: ChessColors.gold.withOpacity(0.8),
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  '9 módulos · 3×3',
                  style: TextStyle(
                    color: ChessColors.gold.withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // ── Board ─────────────────────────────────────────────────────────────────────
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ChessBoardWidget(
                      board: _board,
                      pieces: _gameState.pieces,
                      currentTurn: _gameState.currentTurn,
                      tileSize: 48,
                      onMove: _aiThinking ? null : _handleMove,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom info bar ───────────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: ChessColors.deepPurple.withOpacity(0.6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline,
                    color: ChessColors.gold.withOpacity(0.5), size: 14),
                const SizedBox(width: 6),
                Text(
                  'Precipicios = casillas vacías donde las piezas caen',
                  style: TextStyle(
                    color: ChessColors.gold.withOpacity(0.5),
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleMove(ChessPiece piece, TilePosition dest) {
    setState(() {
      _gameState.move(piece, dest);
      _updateStatus();
    });

    // If vs Computer and it's now black's turn, trigger AI
    if (widget.gameMode == GameMode.vsComputer &&
        _gameState.isOngoing &&
        _gameState.currentTurn == PlayerColor.black) {
      _triggerAI();
    }
  }

  void _triggerAI() {
    setState(() => _aiThinking = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted || !_gameState.isOngoing) return;
      final move = _ai.pickMove(_gameState);
      if (move != null) {
        setState(() {
          _gameState.move(move.piece, move.destination);
          _aiThinking = false;
          _updateStatus();
        });
      } else {
        setState(() {
          _aiThinking = false;
          _statusMsg = '🤝 La computadora no tiene movimientos. Tablas.';
        });
      }
    });
  }

  void _updateStatus() {
    switch (_gameState.status) {
      case GameStatus.whiteWins:
        _statusMsg = '🏆 ¡Blancas ganan! El Rey negro fue capturado.';
      case GameStatus.blackWins:
        if (widget.gameMode == GameMode.vsComputer) {
          _statusMsg = '🏆 ¡La Computadora gana! Tu Rey fue capturado.';
        } else {
          _statusMsg = '🏆 ¡Negras ganan! El Rey blanco fue capturado.';
        }
      case GameStatus.draw:
        _statusMsg = '🤝 Tablas';
      case GameStatus.ongoing:
        final whose = _gameState.currentTurn == PlayerColor.white
            ? 'Blancas ♟'
            : 'Negras ♟';
        if (widget.gameMode == GameMode.vsComputer &&
            _gameState.currentTurn == PlayerColor.black) {
          _statusMsg = '🤖 La computadora piensa...';
        } else {
          _statusMsg = 'Turno de $whose';
        }
    }
  }
}

// ─── Reusable widgets ───────────────────────────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  final String message;
  final GameStatus status;
  final bool aiThinking;

  const _StatusBar({
    required this.message,
    required this.status,
    this.aiThinking = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOver = status != GameStatus.ongoing;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: isOver
          ? ChessColors.gold.withOpacity(0.2)
          : ChessColors.deepPurple,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Icon(
            isOver
                ? Icons.emoji_events
                : aiThinking
                    ? Icons.psychology
                    : Icons.sports_esports,
            color: ChessColors.gold,
            size: 18,
          ),
          const SizedBox(width: 8),
          if (aiThinking) ...[
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ChessColors.gold,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isOver ? ChessColors.goldLight : ChessColors.gold,
                fontWeight: isOver ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
