import 'package:flutter/material.dart';

import 'package:ludo_rank/features/match_players/domain/entities/match_player.dart';

class LudoGameResultOverlay extends StatelessWidget {
  final List<MatchPlayer> players;

  final bool isSaved;
  final bool isLoading;

  final VoidCallback onRetry;
  final VoidCallback? onClose;

  const LudoGameResultOverlay({
    super.key,
    required this.players,
    required this.isSaved,
    required this.isLoading,
    required this.onRetry,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final sortedPlayers = [...players]
      ..sort((a, b) => (a.rank ?? 999).compareTo(b.rank ?? 999));

    return Material(
      color: Colors.black.withValues(alpha: 0.58),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            margin: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSaved ? Icons.emoji_events : Icons.warning_amber,
                    size: 56,
                    color: isSaved
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    isSaved ? 'انتهت المباراة' : 'انتهت اللعبة',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 6),

                  Text(
                    isSaved
                        ? 'تم حفظ ترتيب اللاعبين والنقاط.'
                        : 'اللعبة انتهت، لكن لم يتم حفظ النتيجة في قاعدة البيانات بعد.',
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 18),

                  if (sortedPlayers.isNotEmpty)
                    _ResultsList(players: sortedPlayers),

                  const SizedBox(height: 18),

                  if (!isSaved)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isLoading ? null : onRetry,
                        icon: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.sync),
                        label: Text(
                          isLoading
                              ? 'جاري إعادة الحفظ...'
                              : 'إعادة حفظ النتيجة',
                        ),
                      ),
                    ),

                  if (isSaved && onClose != null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onClose,
                        child: const Text('العودة'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// RESULTS
// ==================================================================

class _ResultsList extends StatelessWidget {
  final List<MatchPlayer> players;

  const _ResultsList({required this.players});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final player in players)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ResultRow(player: player),
          ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final MatchPlayer player;

  const _ResultRow({required this.player});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            child: Text(
              '${player.rank ?? "-"}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              player.playerId,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '${player.points} نقطة',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
