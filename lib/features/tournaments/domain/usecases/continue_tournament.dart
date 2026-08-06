import 'package:ludo_rank/features/tournament_players/domain/repositories/tournament_player_repository.dart';

import '../repositories/tournament_repository.dart';
import '../entities/tournament.dart';
import '../services/tournament_validator.dart';

class ContinueTournament {
  final TournamentRepository tournamentRepository;

  final TournamentPlayerRepository tournamentPlayerRepository;

  final TournamentValidator validator;

  ContinueTournament(
      this.tournamentRepository,
      this.tournamentPlayerRepository,
      this.validator,
      );

  Future<void> call(
      String tournamentId,
      ) async {
    final tournament =
    await tournamentRepository.getTournamentById(
      tournamentId,
    );

    if (tournament == null) {
      throw Exception(
        'Tournament not found',
      );
    }

    final players =
    await tournamentPlayerRepository
        .getTournamentPlayers(
      tournamentId,
    );

    validator.validatePlayers(players);

    final updatedTournament =
    tournament.copyWith(
      status: TournamentStatus.running,
      updatedAt: DateTime.now(),
    );

    await tournamentRepository.updateTournament(
      updatedTournament,
    );
  }
}