
import 'package:flutter/material.dart';

import 'package:ludo_rank/features/match_players/domain/entities/match_player.dart';

import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_player.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/game_result.dart';
import 'package:ludo_rank/features/ludo_game/presentation/widgets/match_ui/match_ui_colors.dart';

class LudoGameResultOverlay extends StatelessWidget {
  final List<MatchPlayer> players;
  final Map<String, String> playerNames;
  final bool isSaved;
  final bool isLoading;

  final VoidCallback onRetry;
  final VoidCallback? onClose;

  final GameResult? gameResult;
  final List<MatchPlayer> matchPlayers;

  // لاعبو المحرك، لاستخراج اللون الحقيقي لكل لاعب.
  final List<LudoPlayer> gamePlayers;

  const LudoGameResultOverlay({
    super.key,
    required this.players,
    this.playerNames = const <String, String>{},
    required this.isSaved,
    required this.isLoading,
    required this.onRetry,
    required this.onClose,
    this.gameResult,
    this.matchPlayers = const <MatchPlayer>[],
    this.gamePlayers = const <LudoPlayer>[],
  });

  @override
  Widget build(BuildContext context) {
    final sortedPlayers = [...players]
      ..sort((a, b) => (a.rank ?? 999).compareTo(b.rank ?? 999));

    // ربط معرف اللاعب بلونه الفعلي في اللعبة.
    final playerColors = <String, Color>{
      for (final player in gamePlayers)
        player.playerId: matchUiColorFor(player.color),
    };

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
                    _ResultsList(
                      players: sortedPlayers,
                      playerNames: playerNames,
                      playerColors: playerColors,
                    )
                  else if (gameResult != null)
                    _EngineResultsList(
                      gameResult: gameResult!,
                      matchPlayers: matchPlayers,
                      playerNames: playerNames,
                      playerColors: playerColors,
                    ),

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
  final Map<String, String> playerNames;
  final Map<String, Color> playerColors;

  const _ResultsList({
    required this.players,
    required this.playerNames,
    required this.playerColors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final player in players)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ResultRow(
              player: player,
              displayName:
              playerNames[player.playerId] ?? 'اللاعب ${player.seat}',
              color: playerColors[player.playerId],
            ),
          ),
      ],
    );
  }
}

// ==================================================================
// RESULT ROW
// ==================================================================

class _ResultRow extends StatelessWidget {
  final MatchPlayer player;
  final String displayName;
  final Color? color;

  const _ResultRow({
    required this.player,
    required this.displayName,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final playerColor = color ?? Colors.grey;
    final isYellow = playerColor == const Color(0xFFF7BE00);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: playerColor.withValues(alpha: 0.09),
        border: Border.all(
          color: playerColor.withValues(alpha: 0.65),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: playerColor,
            foregroundColor: isYellow
                ? const Color(0xFF21182B)
                : Colors.white,
            child: Text(
              '${player.rank ?? "-"}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              displayName,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          Text(
            '${player.points} نقطة',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: playerColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// ENGINE RESULTS
// ==================================================================

class _EngineResultsList extends StatelessWidget {
  final GameResult gameResult;
  final List<MatchPlayer> matchPlayers;
  final Map<String, String> playerNames;
  final Map<String, Color> playerColors;

  const _EngineResultsList({
    required this.gameResult,
    required this.matchPlayers,
    required this.playerNames,
    required this.playerColors,
  });

  @override
  Widget build(BuildContext context) {
    final results = [...gameResult.players]
      ..sort((a, b) => a.rank.compareTo(b.rank));

    return Column(
      children: [
        for (final result in results)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _EngineResultRow(
              rank: result.rank,
              displayName: playerNames[result.playerId] ??
                  _fallbackName(result.playerId),
              color: playerColors[result.playerId],
            ),
          ),
      ],
    );
  }

  String _fallbackName(String playerId) {
    for (final player in matchPlayers) {
      if (player.playerId == playerId) {
        return 'اللاعب ${player.seat}';
      }
    }

    return 'لاعب';
  }
}

// ==================================================================
// ENGINE RESULT ROW
// ==================================================================

class _EngineResultRow extends StatelessWidget {
  final int rank;
  final String displayName;
  final Color? color;

  const _EngineResultRow({
    required this.rank,
    required this.displayName,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final playerColor = color ?? Colors.grey;
    final isYellow = playerColor == const Color(0xFFF7BE00);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: playerColor.withValues(alpha: 0.09),
        border: Border.all(
          color: playerColor.withValues(alpha: 0.65),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: playerColor,
            foregroundColor: isYellow
                ? const Color(0xFF21182B)
                : Colors.white,
            child: Text(
              '$rank',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              displayName,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
