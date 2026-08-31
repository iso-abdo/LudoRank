import '../entities/ludo_player.dart';
import '../entities/position.dart';

class LudoPath {
  /// Main Loop.
  ///
  /// الخطوات:
  /// 0 .. 51
  final List<Position> mainLoopPath;

  /// بعد الـCapture:
  ///
  /// 51 .. 55 = Home Lane
  /// 56       = Finish
  final List<Position> homePath;

  const LudoPath({
    required this.mainLoopPath,
    required this.homePath,
  });

  /// عدد خطوات الـMain Loop.
  static const int mainLoopLength = 52;

  /// آخر خطوة في الـMain Loop.
  static const int lastMainLoopStep = 51;

  /// بداية الـHome Lane بعد الـCapture.
  static const int homeLaneStartStep = 51;

  /// آخر خطوة داخل الـHome Lane.
  static const int homeLaneLastStep = 55;

  /// نقطة النهاية.
  static const int finishStep = 56;

  /// إرجاع مكان الخطوة حسب حالة اللاعب.
  ///
  /// Before Capture:
  ///   0..51 = Main Loop
  ///
  /// After Capture:
  ///   0..50 = Main Loop
  ///   51..55 = Home Lane
  ///   56    = Finish
  Position positionAt({
    required int step,
    required bool hasCaptured,
  }) {
    if (step < 0 || step > finishStep) {
      throw RangeError.range(
        step,
        0,
        finishStep,
        'step',
      );
    }

    if (!hasCaptured) {
      if (step <= lastMainLoopStep) {
        return mainLoopPath[step];
      }

      throw StateError(
        'الخطوة $step غير متاحة قبل الـCapture.',
      );
    }

    if (step <= lastMainLoopStep - 1) {
      return mainLoopPath[step];
    }

    return homePath[
    step - homeLaneStartStep];
  }

  /// الخطوة التالية حسب حالة اللاعب.
  ///
  /// قبل الـCapture:
  /// 50 → 51 → 0
  ///
  /// بعد الـCapture:
  /// 50 → 51 → 52 → 53 → 54 → 55 → 56
  int nextStep({
    required int currentStep,
    required bool hasCaptured,
  }) {
    if (currentStep < 0 ||
        currentStep > finishStep) {
      throw RangeError.range(
        currentStep,
        0,
        finishStep,
        'currentStep',
      );
    }

    // ----------------------------------------------------------
    // AFTER CAPTURE
    // ----------------------------------------------------------

    if (hasCaptured) {
      if (currentStep >= finishStep) {
        return finishStep;
      }

      return currentStep + 1;
    }

    // ----------------------------------------------------------
    // BEFORE CAPTURE
    // ----------------------------------------------------------

    if (currentStep == lastMainLoopStep) {
      return 0;
    }

    return currentStep + 1;
  }

  bool isMainLoopStep(int step) {
    return step >= 0 &&
        step <= lastMainLoopStep;
  }

  bool isHomeLaneStep(int step) {
    return step >= homeLaneStartStep &&
        step <= homeLaneLastStep;
  }

  bool isFinishStep(int step) {
    return step == finishStep;
  }

  Position get startingPosition =>
      mainLoopPath.first;

  Position get finishPosition =>
      homePath.last;

  /// الحصول على المسار حسب لون اللاعب.
  static LudoPath forColor(
      LudoPlayerColor color,
      ) {
    switch (color) {
      case LudoPlayerColor.red:
        return LudoPaths.red;

      case LudoPlayerColor.green:
        return LudoPaths.green;

      case LudoPlayerColor.yellow:
        return LudoPaths.yellow;

      case LudoPlayerColor.blue:
        return LudoPaths.blue;
    }
  }
}