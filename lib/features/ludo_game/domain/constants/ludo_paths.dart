import '../entities/ludo_player.dart';
import '../entities/position.dart';

/// Represents the logical movement path of one Ludo color.
///
/// IMPORTANT:
/// - The main loop contains logical steps 0..51.
/// - Before the first capture, step 51 is the last main-loop cell
///   and the next step wraps to step 0.
/// - After a capture, step 51 becomes the first Home Lane cell.
/// - Step 56 is the final Finish cell.
///
/// Therefore:
/// - mainLoopLength = 52
/// - totalLength = 57
///
/// Step 51 is state-dependent and MUST be resolved through
/// [positionAt] or [nextStep] when game state is relevant.
class LudoPath {
  /// Main-loop physical positions.
  ///
  /// Logical steps:
  /// 0..51
  final List<Position> mainLoopPath;

  /// Home-lane + finish physical positions.
  ///
  /// Logical steps:
  /// 51..55 = Home Lane
  /// 56      = Finish
  final List<Position> homePath;

  const LudoPath({
    required this.mainLoopPath,
    required this.homePath,
  });

  // ============================================================
  // LOGICAL CONSTANTS
  // ============================================================

  /// Number of positions in the circular main loop.
  static const int mainLoopLength = 52;

  /// Last logical step belonging to the main loop.
  static const int lastMainLoopStep = 51;

  /// First Home Lane logical step after Capture.
  static const int homeLaneStartStep = 51;

  /// Last logical step before Finish.
  static const int homeLaneLastStep = 55;

  /// Final logical Finish step.
  static const int finishStep = 56;

  /// Total logical positions in the complete path.
  ///
  /// Steps:
  /// 0..50  = Main Loop
  /// 51..55 = Home Lane
  /// 56     = Finish
  static const int totalLength = finishStep + 1;

  // ============================================================
  // PATH VIEWS
  // ============================================================

  /// Main-loop path used before the first Capture.
  List<Position> get beforeCapture => mainLoopPath;

  /// Full logical path used after Capture.
  ///
  /// Step 51 in this view is the first Home Lane position,
  /// not mainLoopPath[51].
  List<Position> get afterCapture => [
    ...mainLoopPath.take(lastMainLoopStep),
    ...homePath,
  ];

  /// Number of logical positions in the complete path.
  ///
  /// IMPORTANT:
  /// This is 57.
  ///
  /// [mainLoopLength] remains 52 because the circular main loop
  /// itself contains exactly 52 positions.
  int get length => totalLength;

  bool get isEmpty => mainLoopPath.isEmpty;

  bool get isNotEmpty => mainLoopPath.isNotEmpty;

  Position get first => startingPosition;

  Position get last => finishPosition;

  // ============================================================
  // COMPATIBILITY / INDEX ACCESS
  // ============================================================

  /// List-like access to a logical position.
  ///
  /// IMPORTANT:
  /// Step 51 is state-dependent:
  ///
  /// - Before Capture -> mainLoopPath[51]
  /// - After Capture  -> homePath[0]
  ///
  /// Therefore game logic should prefer [positionAt].
  Position operator[](int index) {
    _validateStep(index);

    if (index <= lastMainLoopStep) {
      return mainLoopPath[index];
    }

    return homePath[index - homeLaneStartStep];
  }

  // ============================================================
  // POSITION RESOLUTION
  // ============================================================

  /// Resolves a logical step to its physical board position.
  ///
  /// Before Capture:
  ///   0..51 -> Main Loop
  ///
  /// After Capture:
  ///   0..50 -> Main Loop
  ///   51..55 -> Home Lane
  ///   56 -> Finish
  Position positionAt({
    required int step,
    required bool hasCaptured,
  }) {
    _validateStep(step);

    if (!hasCaptured) {
      return mainLoopPath[step];
    }

    if (step <= lastMainLoopStep - 1) {
      return mainLoopPath[step];
    }

    return homePath[step - homeLaneStartStep];
  }

  // ============================================================
  // STEP TRANSITION
  // ============================================================

  /// Returns the next logical step.
  ///
  /// Before Capture:
  ///   50 -> 51
  ///   51 -> 0
  ///
  /// After Capture:
  ///   50 -> 51
  ///   51 -> 52
  ///   ...
  ///   55 -> 56
  ///   56 -> 56
  int nextStep({
    required int currentStep,
    required bool hasCaptured,
  }) {
    _validateStep(currentStep);

    if (hasCaptured) {
      if (currentStep >= finishStep) {
        return finishStep;
      }

      return currentStep + 1;
    }

    if (currentStep == lastMainLoopStep) {
      return 0;
    }

    return currentStep + 1;
  }

  // ============================================================
  // STEP CLASSIFICATION
  // ============================================================

  bool isMainLoopStep(int step) {
    return step >= 0 && step <= lastMainLoopStep;
  }

  bool isHomeLaneStep(int step) {
    return step >= homeLaneStartStep && step <= homeLaneLastStep;
  }

  bool isFinishStep(int step) {
    return step == finishStep;
  }

  bool isStartingStep(int step) {
    return const {
      0,
      13,
      26,
      39,
    }.contains(step);
  }

  // ============================================================
  // COMMON POSITIONS
  // ============================================================

  Position get startingPosition => mainLoopPath.first;

  Position get finishPosition => homePath.last;

  // ============================================================
  // VALIDATION
  // ============================================================

  void _validateStep(int step) {
    if (step < 0 || step > finishStep) {
      throw RangeError.range(
        step,
        0,
        finishStep,
        'step',
      );
    }
  }
}

/// Provides the predefined board paths for every Ludo color.
class LudoPaths {
  const LudoPaths._();

  // ============================================================
  // RED
  // ============================================================

  static const red = LudoPath(
    mainLoopPath: [
      Position(row: 14, column: 7), // 0
      Position(row: 13, column: 7), // 1
      Position(row: 12, column: 7), // 2
      Position(row: 11, column: 7), // 3
      Position(row: 10, column: 7), // 4
      Position(row: 9, column: 6), // 5
      Position(row: 9, column: 5), // 6
      Position(row: 9, column: 4), // 7
      Position(row: 9, column: 3), // 8
      Position(row: 9, column: 2), // 9
      Position(row: 9, column: 1), // 10
      Position(row: 8, column: 1), // 11
      Position(row: 7, column: 1), // 12
      Position(row: 7, column: 2), // 13
      Position(row: 7, column: 3), // 14
      Position(row: 7, column: 4), // 15
      Position(row: 7, column: 5), // 16
      Position(row: 7, column: 6), // 17
      Position(row: 6, column: 7), // 18
      Position(row: 5, column: 7), // 19
      Position(row: 4, column: 7), // 20
      Position(row: 3, column: 7), // 21
      Position(row: 2, column: 7), // 22
      Position(row: 1, column: 7), // 23
      Position(row: 1, column: 8), // 24
      Position(row: 1, column: 9), // 25
      Position(row: 2, column: 9), // 26
      Position(row: 3, column: 9), // 27
      Position(row: 4, column: 9), // 28
      Position(row: 5, column: 9), // 29
      Position(row: 6, column: 9), // 30
      Position(row: 7, column: 10), // 31
      Position(row: 7, column: 11), // 32
      Position(row: 7, column: 12), // 33
      Position(row: 7, column: 13), // 34
      Position(row: 7, column: 14), // 35
      Position(row: 7, column: 15), // 36
      Position(row: 8, column: 15), // 37
      Position(row: 9, column: 15), // 38
      Position(row: 9, column: 14), // 39
      Position(row: 9, column: 13), // 40
      Position(row: 9, column: 12), // 41
      Position(row: 9, column: 11), // 42
      Position(row: 9, column: 10), // 43
      Position(row: 10, column: 9), // 44
      Position(row: 11, column: 9), // 45
      Position(row: 12, column: 9), // 46
      Position(row: 13, column: 9), // 47
      Position(row: 14, column: 9), // 48
      Position(row: 15, column: 9), // 49
      Position(row: 15, column: 8), // 50
      Position(row: 15, column: 7), // 51
    ],
    homePath: [
      Position(row: 14, column: 8), // 51
      Position(row: 13, column: 8), // 52
      Position(row: 12, column: 8), // 53
      Position(row: 11, column: 8), // 54
      Position(row: 10, column: 8), // 55
      Position(row: 9, column: 8), // 56 Finish
    ],
  );

  // ============================================================
  // GREEN
  // ============================================================

  static const green = LudoPath(
    mainLoopPath: [
      Position(row: 7, column: 2), // 0
      Position(row: 7, column: 3), // 1
      Position(row: 7, column: 4), // 2
      Position(row: 7, column: 5), // 3
      Position(row: 7, column: 6), // 4
      Position(row: 6, column: 7), // 5
      Position(row: 5, column: 7), // 6
      Position(row: 4, column: 7), // 7
      Position(row: 3, column: 7), // 8
      Position(row: 2, column: 7), // 9
      Position(row: 1, column: 7), // 10
      Position(row: 1, column: 8), // 11
      Position(row: 1, column: 9), // 12
      Position(row: 2, column: 9), // 13
      Position(row: 3, column: 9), // 14
      Position(row: 4, column: 9), // 15
      Position(row: 5, column: 9), // 16
      Position(row: 6, column: 9), // 17
      Position(row: 7, column: 10), // 18
      Position(row: 7, column: 11), // 19
      Position(row: 7, column: 12), // 20
      Position(row: 7, column: 13), // 21
      Position(row: 7, column: 14), // 22
      Position(row: 7, column: 15), // 23
      Position(row: 8, column: 15), // 24
      Position(row: 9, column: 15), // 25
      Position(row: 9, column: 14), // 26
      Position(row: 9, column: 13), // 27
      Position(row: 9, column: 12), // 28
      Position(row: 9, column: 11), // 29
      Position(row: 9, column: 10), // 30
      Position(row: 10, column: 9), // 31
      Position(row: 11, column: 9), // 32
      Position(row: 12, column: 9), // 33
      Position(row: 13, column: 9), // 34
      Position(row: 14, column: 9), // 35
      Position(row: 15, column: 9), // 36
      Position(row: 15, column: 8), // 37
      Position(row: 15, column: 7), // 38
      Position(row: 14, column: 7), // 39
      Position(row: 13, column: 7), // 40
      Position(row: 12, column: 7), // 41
      Position(row: 11, column: 7), // 42
      Position(row: 10, column: 7), // 43
      Position(row: 9, column: 6), // 44
      Position(row: 9, column: 5), // 45
      Position(row: 9, column: 4), // 46
      Position(row: 9, column: 3), // 47
      Position(row: 9, column: 2), // 48
      Position(row: 9, column: 1), // 49
      Position(row: 8, column: 1), // 50
      Position(row: 7, column: 1), // 51
    ],
    homePath: [
      Position(row: 8, column: 2), // 51
      Position(row: 8, column: 3), // 52
      Position(row: 8, column: 4), // 53
      Position(row: 8, column: 5), // 54
      Position(row: 8, column: 6), // 55
      Position(row: 8, column: 7), // 56 Finish
    ],
  );

  // ============================================================
  // YELLOW
  // ============================================================

  static const yellow = LudoPath(
    mainLoopPath: [
      Position(row: 2, column: 9), // 0
      Position(row: 3, column: 9), // 1
      Position(row: 4, column: 9), // 2
      Position(row: 5, column: 9), // 3
      Position(row: 6, column: 9), // 4
      Position(row: 7, column: 10), // 5
      Position(row: 7, column: 11), // 6
      Position(row: 7, column: 12), // 7
      Position(row: 7, column: 13), // 8
      Position(row: 7, column: 14), // 9
      Position(row: 7, column: 15), // 10
      Position(row: 8, column: 15), // 11
      Position(row: 9, column: 15), // 12
      Position(row: 9, column: 14), // 13
      Position(row: 9, column: 13), // 14
      Position(row: 9, column: 12), // 15
      Position(row: 9, column: 11), // 16
      Position(row: 9, column: 10), // 17
      Position(row: 10, column: 9), // 18
      Position(row: 11, column: 9), // 19
      Position(row: 12, column: 9), // 20
      Position(row: 13, column: 9), // 21
      Position(row: 14, column: 9), // 22
      Position(row: 15, column: 9), // 23
      Position(row: 15, column: 8), // 24
      Position(row: 15, column: 7), // 25
      Position(row: 14, column: 7), // 26
      Position(row: 13, column: 7), // 27
      Position(row: 12, column: 7), // 28
      Position(row: 11, column: 7), // 29
      Position(row: 10, column: 7), // 30
      Position(row: 9, column: 6), // 31
      Position(row: 9, column: 5), // 32
      Position(row: 9, column: 4), // 33
      Position(row: 9, column: 3), // 34
      Position(row: 9, column: 2), // 35
      Position(row: 9, column: 1), // 36
      Position(row: 8, column: 1), // 37
      Position(row: 7, column: 1), // 38
      Position(row: 7, column: 2), // 39
      Position(row: 7, column: 3), // 40
      Position(row: 7, column: 4), // 41
      Position(row: 7, column: 5), // 42
      Position(row: 7, column: 6), // 43
      Position(row: 6, column: 7), // 44
      Position(row: 5, column: 7), // 45
      Position(row: 4, column: 7), // 46
      Position(row: 3, column: 7), // 47
      Position(row: 2, column: 7), // 48
      Position(row: 1, column: 7), // 49
      Position(row: 1, column: 8), // 50
      Position(row: 1, column: 9), // 51
    ],
    homePath: [
      Position(row: 2, column: 8), // 51
      Position(row: 3, column: 8), // 52
      Position(row: 4, column: 8), // 53
      Position(row: 5, column: 8), // 54
      Position(row: 6, column: 8), // 55
      Position(row: 7, column: 8), // 56 Finish
    ],
  );

  // ============================================================
  // BLUE
  // ============================================================

  static const blue = LudoPath(
    mainLoopPath: [
      Position(row: 9, column: 14), // 0
      Position(row: 9, column: 13), // 1
      Position(row: 9, column: 12), // 2
      Position(row: 9, column: 11), // 3
      Position(row: 9, column: 10), // 4
      Position(row: 10, column: 9), // 5
      Position(row: 11, column: 9), // 6
      Position(row: 12, column: 9), // 7
      Position(row: 13, column: 9), // 8
      Position(row: 14, column: 9), // 9
      Position(row: 15, column: 9), // 10
      Position(row: 15, column: 8), // 11
      Position(row: 15, column: 7), // 12
      Position(row: 14, column: 7), // 13
      Position(row: 13, column: 7), // 14
      Position(row: 12, column: 7), // 15
      Position(row: 11, column: 7), // 16
      Position(row: 10, column: 7), // 17
      Position(row: 9, column: 6), // 18
      Position(row: 9, column: 5), // 19
      Position(row: 9, column: 4), // 20
      Position(row: 9, column: 3), // 21
      Position(row: 9, column: 2), // 22
      Position(row: 9, column: 1), // 23
      Position(row: 8, column: 1), // 24
      Position(row: 7, column: 1), // 25
      Position(row: 7, column: 2), // 26
      Position(row: 7, column: 3), // 27
      Position(row: 7, column: 4), // 28
      Position(row: 7, column: 5), // 29
      Position(row: 7, column: 6), // 30
      Position(row: 6, column: 7), // 31
      Position(row: 5, column: 7), // 32
      Position(row: 4, column: 7), // 33
      Position(row: 3, column: 7), // 34
      Position(row: 2, column: 7), // 35
      Position(row: 1, column: 7), // 36
      Position(row: 1, column: 8), // 37
      Position(row: 1, column: 9), // 38
      Position(row: 2, column: 9), // 39
      Position(row: 3, column: 9), // 40
      Position(row: 4, column: 9), // 41
      Position(row: 5, column: 9), // 42
      Position(row: 6, column: 9), // 43
      Position(row: 7, column: 10), // 44
      Position(row: 7, column: 11), // 45
      Position(row: 7, column: 12), // 46
      Position(row: 7, column: 13), // 47
      Position(row: 7, column: 14), // 48
      Position(row: 7, column: 15), // 49
      Position(row: 8, column: 15), // 50
      Position(row: 9, column: 15), // 51
    ],
    homePath: [
      Position(row: 8, column: 14), // 51
      Position(row: 8, column: 13), // 52
      Position(row: 8, column: 12), // 53
      Position(row: 8, column: 11), // 54
      Position(row: 8, column: 10), // 55
      Position(row: 8, column: 9), // 56 Finish
    ],
  );

  // ============================================================
  // COLOR LOOKUP
  // ============================================================

  static LudoPath forColor(LudoPlayerColor color) {
    switch (color) {
      case LudoPlayerColor.red:
        return red;

      case LudoPlayerColor.green:
        return green;

      case LudoPlayerColor.yellow:
        return yellow;

      case LudoPlayerColor.blue:
        return blue;
    }
  }
}