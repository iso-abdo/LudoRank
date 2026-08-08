import 'package:ludo_rank/features/tournament_players/domain/entities/tournament_player.dart';

class MatchValidator {
  const MatchValidator();

  void validatePlayers({
    required List<TournamentPlayer> tournamentPlayers,
    required List<String> selectedPlayers,
    required int requiredPlayers,
  }) {
    if (selectedPlayers.length != requiredPlayers) {
      throw Exception(
        'عدد اللاعبين غير صحيح.',
      );
    }

    final uniquePlayers = selectedPlayers.toSet();

    if (uniquePlayers.length != selectedPlayers.length) {
      throw Exception(
        'لا يمكن تكرار نفس اللاعب داخل المباراة.',
      );
    }

    final tournamentIds =
    tournamentPlayers.map((e) => e.playerId).toSet();

    for (final playerId in selectedPlayers) {
      if (!tournamentIds.contains(playerId)) {
        throw Exception(
          'يوجد لاعب غير مسجل داخل البطولة.',
        );
      }
    }
  }
}