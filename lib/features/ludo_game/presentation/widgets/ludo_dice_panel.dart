import 'package:flutter/material.dart';

import 'package:ludo_rank/features/ludo_game/domain/models/available_rolls.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/turn_state.dart';

class LudoDicePanel extends StatelessWidget {
  final TurnState? turnState;
  final AvailableRolls availableRolls;

  final bool canRoll;
  final VoidCallback onRoll;

  const LudoDicePanel({
    super.key,
    required this.turnState,
    required this.availableRolls,
    required this.canRoll,
    required this.onRoll,
  });

  @override
  Widget build(BuildContext context) {
    final rolls = turnState?.rolls ?? const [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.casino_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'النرد',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (turnState?.sixRollCount != null)
                  Text(
                    '6 × ${turnState!.sixRollCount}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
              ],
            ),

            const SizedBox(height: 12),

            if (availableRolls.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final roll in availableRolls.rolls)
                    _RollChip(value: roll.value, sequence: roll.sequence),
                ],
              )
            else
              Text(
                turnState?.isRolling == true
                    ? 'اضغط على زر رمي النرد'
                    : 'لا توجد رميات متاحة',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

            const SizedBox(height: 12),

            FilledButton.icon(
              onPressed: canRoll ? onRoll : null,
              icon: const Icon(Icons.casino),
              label: Text(
                canRoll
                    ? 'رمي النرد'
                    : turnState?.isPlaying == true
                    ? 'اختر حركة'
                    : 'النرد غير متاح',
              ),
            ),

            if (rolls.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'سجل الرميات داخل الدور',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: [
                  for (final roll in rolls)
                    Text(
                      '#${roll.sequence}: ${roll.value}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RollChip extends StatelessWidget {
  final int value;
  final int sequence;

  const _RollChip({required this.value, required this.sequence});

  @override
  Widget build(BuildContext context) {
    final isSix = value == 6;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSix
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 5),
          Text('#$sequence', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
