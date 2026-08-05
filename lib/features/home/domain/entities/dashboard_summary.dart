import 'package:ludo_rank/core/database/database.dart';

class DashboardSummary {
  final int playersCount;
  final int tournamentsCount;
  final int matchesCount;
  final int finishedTournamentsCount;

  final Tournament? lastTournament;

  final Match? lastMatch;

  const DashboardSummary({
    required this.playersCount,
    required this.tournamentsCount,
    required this.matchesCount,
    required this.finishedTournamentsCount,
    this.lastTournament,
    this.lastMatch,
  });
}