// Pure Dart tests — no Flutter dependency needed.
import 'package:test/test.dart';
import 'package:viracocha_chess/features/chess/models/tile.dart';
import 'package:viracocha_chess/features/chess/models/module_pattern.dart';
import 'package:viracocha_chess/features/chess/models/chess_module.dart';

void main() {
  group('Tile', () {
    test('normal tile is playable', () {
      const t = Tile(TileType.normal);
      expect(t.isNormal, isTrue);
      expect(t.isVoid,   isFalse);
    });

    test('void tile is impassable', () {
      const t = Tile(TileType.void_);
      expect(t.isVoid,   isTrue);
      expect(t.isNormal, isFalse);
    });

    test('equality', () {
      expect(const Tile(TileType.normal), equals(const Tile(TileType.normal)));
      expect(const Tile(TileType.void_),  isNot(equals(const Tile(TileType.normal))));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('ChessModule — full pattern', () {
    late ChessModule module;
    setUp(() => module = ChessModule(patternType: ModulePatternType.full));

    test('all 9 tiles are normal', () {
      for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 3; c++) {
          expect(module.tileAt(r, c).isNormal, isTrue,
              reason: 'tile ($r,$c) should be normal');
        }
      }
    });

    test('normalTileCount is 9, voidTileCount is 0', () {
      expect(module.normalTileCount, 9);
      expect(module.voidTileCount,   0);
    });

    test('rotation of full module is still full', () {
      final rotated = module.rotateClockwise();
      expect(rotated.normalTileCount, 9);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('ChessModule — cornerCut pattern', () {
    late ChessModule module;
    setUp(() => module = ChessModule(patternType: ModulePatternType.cornerCut));

    test('top-left is void', () {
      expect(module.tileAt(0, 0).isVoid, isTrue);
    });

    test('has 8 normal tiles', () {
      expect(module.normalTileCount, 8);
      expect(module.voidTileCount,   1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('ChessModule — rotation', () {
    test('rotateClockwise moves top-left void to top-right', () {
      // cornerCut: void at (0,0)
      final m = ChessModule(patternType: ModulePatternType.cornerCut);
      expect(m.tileAt(0, 0).isVoid, isTrue);

      // After 1×90° CW: void should be at (0,2)
      final r1 = m.rotateClockwise();
      expect(r1.tileAt(0, 2).isVoid, isTrue,
          reason: 'void should move to top-right after 90° CW');
    });

    test('four rotations return to original', () {
      for (final type in ModulePatternType.values) {
        final original = ChessModule(patternType: type);
        final restored = original.rotateClockwiseN(4);

        for (int r = 0; r < 3; r++) {
          for (int c = 0; c < 3; c++) {
            expect(
              restored.tileAt(r, c),
              equals(original.tileAt(r, c)),
              reason: 'Pattern $type tile ($r,$c) should be restored after 4 rotations',
            );
          }
        }
      }
    });

    test('rotateClockwiseN(1) equals rotateClockwise()', () {
      final m  = ChessModule(patternType: ModulePatternType.lShape);
      final r1 = m.rotateClockwiseN(1);
      final rc = m.rotateClockwise();
      for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 3; c++) {
          expect(r1.tileAt(r, c), equals(rc.tileAt(r, c)));
        }
      }
    });

    test('rotation tracking increments by 90 each time', () {
      final m = ChessModule(patternType: ModulePatternType.full);
      expect(m.rotation, 0);
      expect(m.rotateClockwise().rotation, 90);
      expect(m.rotateClockwiseN(2).rotation, 180);
      expect(m.rotateClockwiseN(3).rotation, 270);
      expect(m.rotateClockwiseN(4).rotation, 0);
    });

    test('lShape rotated 90° CW — voids move correctly', () {
      // lShape original: col 2 is all void
      final m  = ChessModule(patternType: ModulePatternType.lShape);
      expect(m.tileAt(0, 2).isVoid, isTrue);
      expect(m.tileAt(1, 2).isVoid, isTrue);
      expect(m.tileAt(2, 2).isVoid, isTrue);

      // After 90° CW: bottom row should be void
      final r1 = m.rotateClockwise();
      expect(r1.tileAt(2, 0).isVoid, isTrue);
      expect(r1.tileAt(2, 1).isVoid, isTrue);
      expect(r1.tileAt(2, 2).isVoid, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('All 9 patterns exist and have correct size', () {
    for (final type in ModulePatternType.values) {
      test('$type is 3×3', () {
        final m = ChessModule(patternType: type);
        expect(m.grid.length, 3);
        for (final row in m.grid) {
          expect(row.length, 3);
        }
      });

      test('$type total tile count is 9', () {
        final m = ChessModule(patternType: type);
        expect(m.normalTileCount + m.voidTileCount, 9);
      });
    }
  });
}
