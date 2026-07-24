import 'package:ludo_rank/core/database/database.dart';

import '../entities/match.dart';

class GeneratedTournament {
  final List<Match> matches;
  final List<MatchPlayer> matchPlayers;

  const GeneratedTournament({
    required this.matches,
    required this.matchPlayers,
  });
}