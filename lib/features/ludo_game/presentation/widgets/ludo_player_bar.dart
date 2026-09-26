import 'package:flutter/material.dart';

import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_player.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/ludo_game_state.dart';

class LudoPlayerBar extends StatelessWidget {
  final List<LudoPlayer> players;
  final LudoGameState? gameState;

  const LudoPlayerBar({
    super.key,
    required this.players,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    final sortedPlayers = [...players]
      ..sort((a, b) => a.seat.compareTo(b.seat));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'اللاعبون',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final player in sortedPlayers)
                  _PlayerItem(
                    player: player,
                    rank: gameState?.getRankForPlayer(player.playerId),
                    isCurrent:
                        gameState?.currentPlayer.playerId == player.playerId,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerItem extends StatelessWidget {
  final LudoPlayer player;
  final int? rank;
  final bool isCurrent;

  const _PlayerItem({
    required this.player,
    required this.rank,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(player.color);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? color : color.withValues(alpha: 0.25),
          width: isCurrent ? 2 : 1,
        ),
        color: color.withValues(alpha: isCurrent ? 0.10 : 0.04),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: color,
            child: Text(
              '${player.seat}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            player.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (rank != null) ...[
            const SizedBox(width: 7),
            _RankBadge(rank: rank!),
          ],
        ],
      ),
    );
  }

  Color _colorFor(LudoPlayerColor color) {
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

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.secondaryContainer,
      ),
      child: Text(
        '#$rank',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}
