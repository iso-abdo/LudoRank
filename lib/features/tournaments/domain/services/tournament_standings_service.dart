import 'package:ludo_rank/features/matches/domain/entities/match.dart';
import 'package:ludo_rank/features/matches/domain/entities/match_status.dart';
import 'package:ludo_rank/features/matches/domain/repositories/match_repository.dart';
import 'package:ludo_rank/features/match_players/domain/entities/match_player.dart';
import 'package:ludo_rank/features/match_players/domain/repositories/match_player_repository.dart';
import 'package:ludo_rank/features/tournament_players/domain/entities/tournament_player.dart';
import 'package:ludo_rank/features/tournaments/domain/services/tournament_standings_calculator.dart';

class TournamentStandingsSnapshot {
  final List<Match> matches;
  final List<TournamentStanding> standings;

  const TournamentStandingsSnapshot({
    required this.matches,
    required this.standings,
  });

  int get completedMatches =>
      matches.where((match) => match.status == MatchStatus.finished).length;
}

class TournamentStandingsService {
  final MatchRepository matchRepository;
  final MatchPlayerRepository matchPlayerRepository;
  final TournamentStandingsCalculator calculator;

  const TournamentStandingsService({
    required this.matchRepository,
    required this.matchPlayerRepository,
    this.calculator = const TournamentStandingsCalculator(),
  });

  Future<TournamentStandingsSnapshot> load({
    required String tournamentId,
    required List<TournamentPlayer> participants,
  }) async {
    final matches = await matchRepository.getTournamentMatches(tournamentId);

    final results = <MatchPlayer>[];

    for (final match in matches) {
      if (match.status != MatchStatus.finished) continue;

      final players = await matchPlayerRepository.getMatchPlayers(match.id);

      results.addAll(players);
    }

    final standings = calculator.calculate(
      participantIds: participants.map((player) => player.playerId).toList(),
      matches: matches,
      matchPlayers: results,
    );

    return TournamentStandingsSnapshot(
      matches: List.unmodifiable(matches),
      standings: standings,
    );
  }
}
