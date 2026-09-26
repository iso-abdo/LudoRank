import 'package:flutter/material.dart';

import 'package:ludo_rank/features/ludo_game/domain/models/move_option.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/turn_state.dart';

class LudoMoveHint extends StatelessWidget {
  final String? selectedTokenId;

  final List<MoveOption> availableMoves;

  final TurnState? turnState;

  final ValueChanged<MoveOption> onMove;

  const LudoMoveHint({
    super.key,
    required this.selectedTokenId,
    required this.availableMoves,
    required this.turnState,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    if (turnState?.isPlaying != true) {
      return const SizedBox.shrink();
    }

    final moves = _movesForSelectedToken();

    if (selectedTokenId == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.touch_app_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  availableMoves.isEmpty
                      ? 'لا توجد حركة قانونية متاحة.'
                      : 'اختر Token مضيئًا على اللوحة.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (moves.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            'الـ Token المحدد لا يملك حركة قانونية بهذه الرميات.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_run),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الحركات المتاحة',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final move in moves)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MoveButton(
                  move: move,
                  turnState: turnState!,
                  onPressed: () {
                    onMove(move);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<MoveOption> _movesForSelectedToken() {
    if (selectedTokenId == null) {
      return const [];
    }

    return availableMoves
        .where((move) => _tokenIdForMove(move) == selectedTokenId)
        .toList(growable: false);
  }

  String _tokenIdForMove(MoveOption move) {
    if (move is MoveToken) {
      return move.tokenId;
    }

    if (move is ExitToken) {
      return move.tokenId;
    }

    return '';
  }
}

// ==================================================================
// MOVE BUTTON
// ==================================================================

class _MoveButton extends StatelessWidget {
  final MoveOption move;
  final TurnState turnState;
  final VoidCallback onPressed;

  const _MoveButton({
    required this.move,
    required this.turnState,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final title = _title();

    final subtitle = _subtitle();

    return FilledButton.tonal(
      onPressed: onPressed,
      child: Row(
        children: [
          const Icon(Icons.arrow_forward),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _title() {
    if (move is ExitToken) {
      return 'إخراج الـ Token';
    }

    final normalMove = move as MoveToken;

    return 'تحريك ${normalMove.steps} خطوة';
  }

  String _subtitle() {
    for (final roll in turnState.rolls) {
      if (roll.sequence == move.rollSequence) {
        return 'الرمية #${roll.sequence} = ${roll.value}';
      }
    }

    return 'الرمية #${move.rollSequence}';
  }
}
