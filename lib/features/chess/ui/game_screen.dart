import 'package:flutter/material.dart';
import '../board/game_board.dart';
import '../models/board_coordinate.dart';
import '../models/chess_module.dart';
import '../models/module_pattern.dart';
import '../pieces/chess_piece.dart';
import '../pieces/game_state.dart';
import 'chess_board_widget.dart';
import 'chess_colors.dart';
import 'module_palette_widget.dart';

/// Main game screen — assembles board + palette + status bar.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameBoard    _board;
  late GameState    _gameState;
  ModulePatternType _selectedPattern = ModulePatternType.full;
  int               _pendingRotation = 0;
  String            _statusMsg       = 'Construye el tablero';

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    _board = GameBoard();
    // Single full module at center coordinate (0,0)
    _board.placeFirstModule(
      ChessModule(patternType: ModulePatternType.full),
      const BoardCoordinate(0, 0),
    );

    _gameState = GameState(board: _board);

    // Place kings on valid tiles of the single module
    // Module at (0,0) occupies world tiles rows 0-2, cols 0-2
    _gameState.addPiece(const ChessPiece(
      type: PieceType.king,
      color: PlayerColor.white,
      position: TilePosition(1, 1),
    ));
    _gameState.addPiece(const ChessPiece(
      type: PieceType.king,
      color: PlayerColor.black,
      position: TilePosition(0, 2),
    ));
    _statusMsg = '♟ Turno de las Blancas';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChessColors.background,
      appBar: AppBar(
        backgroundColor: ChessColors.deepPurple,
        title: const Text(
          'VIRACOCHA CHESS',
          style: TextStyle(
            color: ChessColors.gold,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
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
          _StatusBar(message: _statusMsg, status: _gameState.status),

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
                      onMove: _handleMove,
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
      switch (_gameState.status) {
        case GameStatus.whiteWins:
          _statusMsg = '🏆 ¡Blancas ganan! El Rey negro fue capturado.';
        case GameStatus.blackWins:
          _statusMsg = '🏆 ¡Negras ganan! El Rey blanco fue capturado.';
        case GameStatus.draw:
          _statusMsg = '🤝 Tablas';
        case GameStatus.ongoing:
          final whose = _gameState.currentTurn == PlayerColor.white
              ? 'Blancas ♟'
              : 'Negras ♟';
          _statusMsg = 'Turno de $whose';
      }
    });
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

  const _StatusBar({required this.message, required this.status});

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
            isOver ? Icons.emoji_events : Icons.sports_esports,
            color: ChessColors.gold,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            message,
            style: TextStyle(
              color: isOver ? ChessColors.goldLight : ChessColors.gold,
              fontWeight: isOver ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
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
