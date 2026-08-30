import '../entities/ludo_player.dart';
import '../entities/position.dart';

class LudoPath {
  final List<Position> beforeCapture;
  final List<Position> afterCapture;

  const LudoPath({
    required this.beforeCapture,
    required this.afterCapture,
  });

  /// آخر خطوة في Main Loop قبل الدخول للحالة بعد الـCapture.
  static const int mainLoopLastStep = 50;

  /// الخطوة 51 لها معنيان:
  ///
  /// قبل Capture:
  ///   51 -> آخر خانة في الـLoop
  ///
  /// بعد Capture:
  ///   51 -> أول خانة في Home Lane
  static const int transitionStep = 51;

  /// آخر خطوة في اللعبة.
  static const int finishStep = 56;

  int get beforeCaptureLength =>
      beforeCapture.length;

  int get afterCaptureLength =>
      afterCapture.length;

  /// إرجاع الـPosition الفعلية حسب حالة اللاعب.
  Position positionAt({
    required int step,
    required bool hasCaptured,
  }) {
    final path = hasCaptured
        ? afterCapture
        : beforeCapture;

    if (step < 0 || step >= path.length) {
      throw RangeError.range(
        step,
        0,
        path.length - 1,
        'step',
      );
    }

    return path[step];
  }

  /// عدد الخانات في الـMain Loop قبل الـCapture.
  bool isMainLoopStep(int step) {
    return step >= 0 &&
        step <= mainLoopLastStep;
  }

  /// هل الخطوة جزء من الـHome Lane بعد الـCapture؟
  bool isHomeLaneStep(int step) {
    return step >= transitionStep &&
        step < finishStep;
  }

  /// هل الخطوة هي نقطة النهاية؟
  bool isFinishStep(int step) {
    return step == finishStep;
  }

  /// الحصول على الخطوة التالية.
  ///
  /// قبل Capture:
  /// 50 -> 51 -> 0
  ///
  /// بعد Capture:
  /// 50 -> 51 -> 52 -> ... -> 56
  int nextStep({
    required int currentStep,
    required bool hasCaptured,
  }) {
    if (hasCaptured) {
      if (currentStep >= finishStep) {
        return finishStep;
      }

      return currentStep + 1;
    }

    if (currentStep == mainLoopLastStep) {
      return transitionStep;
    }

    if (currentStep == transitionStep) {
      return 0;
    }

    return currentStep + 1;
  }

  /// هل خانة البداية الآمنة؟
  bool isStartingStep(int step) {
    const startingSteps = {
      0,
      13,
      26,
      39,
    };

    return startingSteps.contains(step);
  }
}

class LudoPaths {
  const LudoPaths._();

  static const red = LudoPath(
    beforeCapture: [
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

    afterCapture: [
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
      Position(row: 14, column: 8), // 51
      Position(row: 13, column: 8), // 52
      Position(row: 12, column: 8), // 53
      Position(row: 11, column: 8), // 54
      Position(row: 10, column: 8), // 55
      Position(row: 9, column: 8), // 56
    ],
  );
}