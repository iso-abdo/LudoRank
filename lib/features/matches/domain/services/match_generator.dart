/*import 'package:uuid/uuid.dart';

import 'package:ludo_rank/features/matches/domain/entities/match.dart';
import 'package:ludo_rank/features/match_players/domain/entities/match_player.dart';
import 'package:ludo_rank/features/tournament_players/domain/entities/tournament_player.dart';

import '../entities/match_status.dart';
import 'generated_tournament.dart';

class MatchGenerator {
  MatchGenerator({
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  GeneratedTournament generate({
    required String tournamentId,
    required List<TournamentPlayer> players,
    required int playersPerMatch,
  }) {
    final matches = <Match>[];

    final matchPlayers = <MatchPlayer>[];

    if (players.isEmpty) {
      return GeneratedTournament(
        matches: matches,
        matchPlayers: matchPlayers,
      );
    }

    int round = 1;

    for (
    int i = 0;
    i < players.length;
    i += playersPerMatch
    ) {
      final group = players.skip(i).take(playersPerMatch).toList();

      final matchId = _uuid.v4();

      matches.add(
        Match(
          id: matchId,
          tournamentId: tournamentId,
          round: round,
          status: MatchStatus.waiting,
          winnerId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      for (int seat = 0; seat < group.length; seat++) {
        final player = group[seat];

        matchPlayers.add(
          MatchPlayer(
            id: _uuid.v4(),
            matchId: matchId,
            playerId: player.playerId,
            seat: seat + 1,
            rank: null,
            points: 0,
            finished: false,
          ),
        );
      }

      round++;
    }

    return GeneratedTournament(
      matches: matches,
      matchPlayers: matchPlayers,
    );
  }
}*/