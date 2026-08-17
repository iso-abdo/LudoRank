import 'package:equatable/equatable.dart';

import 'dice_roll.dart';

class AvailableRolls extends Equatable {
  final List<DiceRoll> rolls;

  const AvailableRolls({
    this.rolls = const [],
  });

  bool get isEmpty => rolls.isEmpty;

  bool get isNotEmpty => rolls.isNotEmpty;

  int get count => rolls.length;

  List<int> get values {
    return List.unmodifiable(
      rolls.map((roll) => roll.value),
    );
  }

  bool containsSequence(int sequence) {
    return rolls.any(
          (roll) => roll.sequence == sequence,
    );
  }

  DiceRoll? getBySequence(int sequence) {
    try {
      return rolls.firstWhere(
            (roll) => roll.sequence == sequence,
      );
    } catch (_) {
      return null;
    }
  }

  AvailableRolls add(DiceRoll roll) {
    return AvailableRolls(
      rolls: [
        ...rolls,
        roll,
      ],
    );
  }

  AvailableRolls removeBySequence(int sequence) {
    var removed = false;

    final updatedRolls = <DiceRoll>[];

    for (final roll in rolls) {
      if (!removed && roll.sequence == sequence) {
        removed = true;
        continue;
      }

      updatedRolls.add(roll);
    }

    return AvailableRolls(
      rolls: List.unmodifiable(updatedRolls),
    );
  }

  AvailableRolls clear() {
    return const AvailableRolls();
  }

  @override
  List<Object?> get props => [
    rolls,
  ];
}