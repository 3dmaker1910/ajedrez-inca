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
import 'module_palette_widget.dart';

/// Main game screen — assembles board + palette + status bar.
/// Now accepts a [gameMode] to enable AI or 2-player mode.
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
  ModulePatternType _selectedPattern = ModulePatternType.full;
  int               _pendingRotation = 0;
  String            _statusMsg       = 'Construye el tablero';
  final SimpleAI    _ai = SimpleAI();
  bool              _aiThinking = false;
  final Random      _rng = Random();

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    _board = GameBoard();

    // Pick a random layout from the 4 predefined ones
    _currentLayout = BoardLayouts.random(_rng);

    // Apply the layout (places modules on the board)
    _currentLayout.applyTo(_board);

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
            tooltip: 'Nueva partida',
            onPressed: () => setState(_initGame),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Status bar ────────────────────────────────────────────────────
          _StatusBar(
            message: _statusMsg,
            status: _gameState.status,
            aiThinking: _aiThinking,
          ),

          // ── Layout name chip ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            color: ChessColors.deepPurple.withOpacity(0.8),
            child: Text(
              '📐 ${_currentLayout.name} — ${_currentLayout.description}',
              style: TextStyle(
                color: ChessColors.gold.withOpacity(0.7),
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // ── Board ─────────────────────────────────────────────────────────
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
                      tileSize: 52,
                      onMove: _aiThinking ? null : _handleMove,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Module palette ────────────────────────────────────────────────
          const Divider(color: ChessColors.moduleBorder, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Text(
                  'Módulos',
                  style: TextStyle(
                    color: ChessColors.gold.withOpacity(0.7),
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ModulePaletteWidget(
                    selected: _selectedPattern,
                    onModuleSelected: (p) =>
                        setState(() => _selectedPattern = p),
                  ),
                ),
                // Rotate button
                _GoldIconButton(
                  icon: Icons.rotate_right,
                  tooltip: 'Rotar módulo',
                  onPressed: () =>
                      setState(() => _pendingRotation = (_pendingRotation + 1) % 4),
                ),
              ],
            ),
          ),

          // ── Place module button ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChessColors.gold,
                  foregroundColor: ChessColors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: Text(
                  'Añadir módulo (rot ${_pendingRotation * 90}°)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: _addModule,
              ),
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
    // Delay to simulate "thinking" and allow UI to update
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

  void _addModule() {
    // Find first empty adjacent coord
    BoardCoordinate? target;
    for (final coord in _board.modules.keys) {
      for (final adj in coord.adjacentModules) {
        if (!_board.modules.containsKey(adj)) {
          target = adj;
          break;
        }
      }
      if (target != null) break;
    }
    if (target == null) return;

    final module = ChessModule(patternType: _selectedPattern)
        .rotateClockwiseN(_pendingRotation);
    setState(() {
      _board.placeModule(module, target!);
      _pendingRotation = 0;
      _statusMsg = 'Módulo ${_selectedPattern.name} añadido en $target';
    });
  }
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

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

class _GoldIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _GoldIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: ChessColors.gold),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}
