import 'package:flutter_test/flutter_test.dart';

import 'package:ludo_rank/features/ludo_game/domain/constants/ludo_paths.dart';
import 'package:ludo_rank/features/ludo_game/domain/constants/safe_cells.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/position.dart';

void main() {
  group('Red LudoPath', () {
    const path = LudoPaths.red;

    test(
      'beforeCapture path contains steps 0 through 51',
          () {
        expect(
          path.beforeCapture.length,
          52,
        );
      },
    );

    test(
      'afterCapture path contains steps 0 through 56',
          () {
        expect(
          path.afterCapture.length,
          57,
        );
      },
    );

    test(
      'beforeCapture step 51 is (15,7)',
          () {
        expect(
          path.positionAt(
            step: 51,
            hasCaptured: false,
          ),
          const Position(
            row: 15,
            column: 7,
          ),
        );
      },
    );

    test(
      'beforeCapture step 51 returns to step 0',
          () {
        expect(
          path.nextStep(
            currentStep: 50,
            hasCaptured: false,
          ),
          51,
        );

        expect(
          path.nextStep(
            currentStep: 51,
            hasCaptured: false,
          ),
          0,
        );
      },
    );

    test(
      'afterCapture step 51 is (14,8)',
          () {
        expect(
          path.positionAt(
            step: 51,
            hasCaptured: true,
          ),
          const Position(
            row: 14,
            column: 8,
          ),
        );
      },
    );

    test(
      'afterCapture home lane is 51 through 55',
          () {
        for (var step = 51; step <= 55; step++) {
          expect(
            path.isHomeLaneStep(step),
            isTrue,
            reason: 'step $step should be Home Lane',
          );
        }

        expect(
          path.isHomeLaneStep(50),
          isFalse,
        );

        expect(
          path.isHomeLaneStep(56),
          isFalse,
        );
      },
    );

    test(
      'afterCapture home lane follows exact coordinates',
          () {
        expect(
          path.positionAt(
            step: 51,
            hasCaptured: true,
          ),
          const Position(
            row: 14,
            column: 8,
          ),
        );

        expect(
          path.positionAt(
            step: 52,
            hasCaptured: true,
          ),
          const Position(
            row: 13,
            column: 8,
          ),
        );

        expect(
          path.positionAt(
            step: 53,
            hasCaptured: true,
          ),
          const Position(
            row: 12,
            column: 8,
          ),
        );

        expect(
          path.positionAt(
            step: 54,
            hasCaptured: true,
          ),
          const Position(
            row: 11,
            column: 8,
          ),
        );

        expect(
          path.positionAt(
            step: 55,
            hasCaptured: true,
          ),
          const Position(
            row: 10,
            column: 8,
          ),
        );
      },
    );

    test(
      'step 56 is the finish',
          () {
        expect(
          path.isFinishStep(56),
          isTrue,
        );

        expect(
          path.positionAt(
            step: 56,
            hasCaptured: true,
          ),
          const Position(
            row: 9,
            column: 8,
          ),
        );
      },
    );

    test(
      'all eight safe cells are recognized',
          () {
        const expected = [
          Position(row: 14, column: 7),
          Position(row: 7, column: 2),
          Position(row: 2, column: 9),
          Position(row: 9, column: 14),
          Position(row: 9, column: 3),
          Position(row: 3, column: 7),
          Position(row: 7, column: 13),
          Position(row: 8, column: 15),
        ];

        expect(
          SafeCells.all.length,
          8,
        );

        for (final position in expected) {
          expect(
            SafeCells.contains(position),
            isTrue,
          );
        }
      },
    );

    test(
      'starting steps are 0, 13, 26, 39',
          () {
        expect(path.isStartingStep(0), isTrue);
        expect(path.isStartingStep(13), isTrue);
        expect(path.isStartingStep(26), isTrue);
        expect(path.isStartingStep(39), isTrue);

        expect(path.isStartingStep(1), isFalse);
        expect(path.isStartingStep(8), isFalse);
      },
    );
  });
}