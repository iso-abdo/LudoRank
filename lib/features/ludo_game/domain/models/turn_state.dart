import 'package:equatable/equatable.dart';
import 'available_rolls.dart';
import 'dice_roll.dart';

enum TurnPhase {
  /// اللاعب في مرحلة جمع الرميات.
  rolling,

  /// اللاعب لديه رميات متاحة ويختار الحركات.
  playing,

  /// تم إلغاء الدور.
  cancelled,

  /// انتهى الدور.
  completed,
}

class TurnState extends Equatable {
  /// اللاعب صاحب الدور الحالي.
  final String playerId;

  /// جميع الرميات التي حدثت داخل هذا الدور.
  ///
  /// مثال:
  /// 6 → 4 → 6 → 3 → 6
  ///
  /// تبقى محفوظة بالكامل هنا.
  final List<DiceRoll> rolls;

  /// الرميات التي لم يتم استخدامها بعد.
  final AvailableRolls availableRolls;

  /// عدد مرات ظهور الرقم 6 داخل نفس الدور.
  ///
  /// مهم:
  /// هذا ليس عدد الـ 6 المتتالية.
  ///
  /// مثال:
  /// 6 → 4 → 6
  /// sixRollCount = 2
  final int sixRollCount;

  /// المرحلة الحالية من الدور.
  final TurnPhase phase;

  const TurnState({
    required this.playerId,
    this.rolls = const [],
    this.availableRolls = const AvailableRolls(),
    this.sixRollCount = 0,
    this.phase = TurnPhase.rolling,
  }) : assert(sixRollCount >= 0);

  factory TurnState.initial(String playerId) {
    return TurnState(
      playerId: playerId,
    );
  }

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

  /// وصلنا لثالث 6 داخل نفس الدور.
  bool get reachedSixLimit =>
      sixRollCount >= 3;

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

  @override
  List<Object?> get props => [
        playerId,
        rolls,
        availableRolls,
        sixRollCount,
        phase,
      ];

  TurnState copyWith({
    String? playerId,
    List<DiceRoll>? rolls,
    AvailableRolls? availableRolls,
    int? sixRollCount,
    TurnPhase? phase,
  }) {
    return TurnState(
      playerId: playerId ?? this.playerId,
      rolls: List.unmodifiable(
        rolls ?? this.rolls,
      ),
      availableRolls:
      availableRolls ?? this.availableRolls,
      sixRollCount:
      sixRollCount ?? this.sixRollCount,
      phase: phase ?? this.phase,
    );
  }
}
