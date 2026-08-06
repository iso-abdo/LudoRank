import 'package:ludo_rank/features/tournament_players/domain/entities/tournament_player.dart';

class TournamentValidator {
  const TournamentValidator();

  void validatePlayers(
      List<TournamentPlayer> players,
      ) {
    if (players.length < 2) {
      throw Exception(
        'يجب أن تحتوي البطولة على لاعبين على الأقل.',
      );
    }

    final ids = players
        .map((e) => e.playerId)
        .toSet();

    if (ids.length != players.length) {
      throw Exception(
        'لا يمكن تكرار نفس اللاعب داخل البطولة.',
      );
    }
  }
}