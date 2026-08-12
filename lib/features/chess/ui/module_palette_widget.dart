import 'package:flutter/material.dart';
import '../models/chess_module.dart';
import '../models/module_pattern.dart';
import '../models/tile.dart';
import 'chess_colors.dart';

/// A horizontal palette showing all 9 module patterns.
/// Tapping a module fires [onModuleSelected].
class ModulePaletteWidget extends StatelessWidget {
  final ModulePatternType? selected;
  final ValueChanged<ModulePatternType> onModuleSelected;

  const ModulePaletteWidget({
    super.key,
    this.selected,
    required this.onModuleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: ModulePatternType.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final patternType = ModulePatternType.values[index];
          final isSelected  = patternType == selected;
          return GestureDetector(
            onTap: () => onModuleSelected(patternType),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? ChessColors.gold : ChessColors.moduleBorder,
                  width: isSelected ? 2.5 : 1,
                ),
                borderRadius: BorderRadius.circular(6),
                color: isSelected
                    ? ChessColors.gold.withOpacity(0.15)
                    : ChessColors.deepPurple,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: ChessColors.gold.withOpacity(0.4),
                          blurRadius: 8,
                        )
                      ]
                    : null,
              ),
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MiniModuleGrid(patternType: patternType),
                  const SizedBox(height: 2),
                  Text(
                    _shortName(patternType),
                    style: TextStyle(
                      color: isSelected ? ChessColors.gold : ChessColors.gold.withOpacity(0.6),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _shortName(ModulePatternType t) {
    switch (t) {
      case ModulePatternType.full:        return 'Full';
      case ModulePatternType.cornerCut:   return 'Corner';
      case ModulePatternType.diagonalCut: return 'Diag';
      case ModulePatternType.lShape:      return 'L-Shape';
      case ModulePatternType.tShape:      return 'T-Shape';
      case ModulePatternType.crossVoid:   return 'Cross';
      case ModulePatternType.ringVoid:    return 'Ring';
      case ModulePatternType.halfSplit:   return 'Half';
      case ModulePatternType.checkerboard: return 'Check';
    }
  }
}

/// A tiny 3×3 grid preview of a module pattern.
class _MiniModuleGrid extends StatelessWidget {
  final ModulePatternType patternType;
  final double cellSize;

  const _MiniModuleGrid({
    required this.patternType,
    this.cellSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final module = ChessModule(patternType: patternType);
    return SizedBox(
      width:  cellSize * 3,
      height: cellSize * 3,
      child: CustomPaint(
        painter: _MiniModulePainter(module: module, cellSize: cellSize),
      ),
    );
  }
}

class _MiniModulePainter extends CustomPainter {
  final ChessModule module;
  final double cellSize;

  const _MiniModulePainter({required this.module, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        final tile  = module.tileAt(r, c);
        final rect  = Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize);
        final color = tile.isVoid
            ? ChessColors.voidTile
            : ((r + c).isEven ? ChessColors.normalTileA : ChessColors.normalTileB);
        canvas.drawRect(rect, Paint()..color = color);
        canvas.drawRect(
          rect,
          Paint()
            ..color   = ChessColors.moduleBorder.withOpacity(0.5)
            ..style   = PaintingStyle.stroke
            ..strokeWidth = 0.5,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniModulePainter old) => old.module != module;
}
