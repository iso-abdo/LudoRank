/*import 'package:uuid/uuid.dart';

import '../../tournament_players/domain/entities/tournament_player.dart';

import '../entities/match.dart';
import '../entities/match_player.dart';

import 'generated_tournament.dart';

class MatchGenerator {
  MatchGenerator();

  final _uuid = const Uuid();

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

    for (int i = 0; i < players.length; i += playersPerMatch) {
      final group = players.skip(i).take(playersPerMatch).toList();

      final matchId = _uuid.v4();

      matches.add(
        Match(
          id: matchId,
          tournamentId: tournamentId,
          round: round++,
          status: MatchStatus.pending,
          winnerId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      for (int seat = 0; seat < group.length; seat++) {
        matchPlayers.add(
          MatchPlayer(
            id: _uuid.v4(),
            matchId: matchId,
            playerId: group[seat].playerId,
            seat: seat + 1,
            rank: null,
            points: 0,
            finished: false,
          ),
        );
      }
    }

    return GeneratedTournament(
      matches: matches,
      matchPlayers: matchPlayers,
    );
  }
}*/