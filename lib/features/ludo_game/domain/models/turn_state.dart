import 'available_rolls.dart';
import 'dice_roll.dart';

enum TurnPhase {
  rolling,
  playing,
  cancelled,
  completed,
}

class TurnState {
  /// اللاعب صاحب الدور الحالي.
  final String playerId;

  /// كل الرميات التي حدثت أثناء هذا الدور.
  ///
  /// مثال:
  /// [6]
  /// [6, 4]
  /// [6, 6, 4]
  final List<DiceRoll> rolls;

  /// الرميات التي لم يتم استخدامها بعد.
  final AvailableRolls availableRolls;

  /// عدد الـ 6 المتتالية.
  ///
  /// 0 = لا يوجد
  /// 1 = أول 6
  /// 2 = ثانيتان 6
  /// 3 = الدور تم إلغاؤه
  final int consecutiveSixes;

  /// المرحلة الحالية من الدور.
  final TurnPhase phase;

  const TurnState({
    required this.playerId,
    this.rolls = const [],
    this.availableRolls = const AvailableRolls(),
    this.consecutiveSixes = 0,
    this.phase = TurnPhase.rolling,
  }) : assert(consecutiveSixes >= 0);

  bool get isRolling =>
      phase == TurnPhase.rolling;

  bool get isPlaying =>
      phase == TurnPhase.playing;

  bool get isCancelled =>
      phase == TurnPhase.cancelled;

  bool get isCompleted =>
      phase == TurnPhase.completed;

  bool get hasAvailableRolls =>
      availableRolls.isNotEmpty;

  bool get hasRolledSix =>
      consecutiveSixes > 0;

  bool get hasTwoConsecutiveSixes =>
      consecutiveSixes >= 2;

  bool get hasThreeConsecutiveSixes =>
      consecutiveSixes >= 3;

  int? get lastRoll {
    if (rolls.isEmpty) {
      return null;
    }

    return rolls.last.value;
  }

  DiceRoll? get lastDiceRoll {
    if (rolls.isEmpty) {
      return null;
    }

    return rolls.last;
  }

  TurnState copyWith({
    String? playerId,
    List<DiceRoll>? rolls,
    AvailableRolls? availableRolls,
    int? consecutiveSixes,
    TurnPhase? phase,
  }) {
    return TurnState(
      playerId: playerId ?? this.playerId,
      rolls: List.unmodifiable(
        rolls ?? this.rolls,
      ),
      availableRolls:
      availableRolls ?? this.availableRolls,
      consecutiveSixes:
      consecutiveSixes ?? this.consecutiveSixes,
      phase: phase ?? this.phase,
    );
  }

  factory TurnState.initial(String playerId) {
    return TurnState(
      playerId: playerId,
    );
  }
}