import 'package:flutter/material.dart';

import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_player.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/turn_state.dart';

class LudoTurnIndicator extends StatelessWidget {
  final LudoPlayer? currentPlayer;
  final TurnState? turnState;

  const LudoTurnIndicator({
    super.key,
    required this.currentPlayer,
    required this.turnState,
  });

  @override
  Widget build(BuildContext context) {
    if (currentPlayer == null) {
      return const SizedBox.shrink();
    }

    final player = currentPlayer!;
    final phase = turnState?.phase;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: _playerColor(player.color),
              child: const Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الدور الحالي',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    player.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            _PhaseChip(phase: phase),
          ],
        ),
      ),
    );
  }

  Color _playerColor(LudoPlayerColor color) {
    switch (color) {
      case LudoPlayerColor.green:
        return const Color(0xFF20B26B);

      case LudoPlayerColor.yellow:
        return const Color(0xFFF2B705);

      case LudoPlayerColor.blue:
        return const Color(0xFF4285F4);

      case LudoPlayerColor.red:
        return const Color(0xFFE94B4B);
    }
  }
}

class _PhaseChip extends StatelessWidget {
  final TurnPhase? phase;

  const _PhaseChip({required this.phase});

  @override
  Widget build(BuildContext context) {
    final text = _title(phase);

    return Chip(avatar: Icon(_icon(phase), size: 17), label: Text(text));
  }

  String _title(TurnPhase? phase) {
    switch (phase) {
      case TurnPhase.rolling:
        return 'رمي النرد';

      case TurnPhase.playing:
        return 'اختر حركة';

      case TurnPhase.cancelled:
        return 'تم الإلغاء';

      case TurnPhase.completed:
        return 'انتهى الدور';

      case null:
        return 'جاري';
    }
  }

  IconData _icon(TurnPhase? phase) {
    switch (phase) {
      case TurnPhase.rolling:
        return Icons.casino_outlined;

      case TurnPhase.playing:
        return Icons.touch_app_outlined;

      case TurnPhase.cancelled:
        return Icons.block;

      case TurnPhase.completed:
        return Icons.check_circle_outline;

      case null:
        return Icons.hourglass_empty;
    }
  }
}
