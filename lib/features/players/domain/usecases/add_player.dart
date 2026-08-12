import 'package:ludo_rank/features/players/domain/repositories/player_repository.dart';

import '../entities/player.dart';

class AddPlayer {
  final PlayerRepository repository;

  AddPlayer(this.repository);

  Future<void> call(Player player) async {
    final name = player.name.trim();

    if (name.isEmpty) {
      throw ArgumentError(
        'اسم اللاعب لا يمكن أن يكون فارغًا.',
      );
    }

    final players = await repository.getAllPlayers();

    final exists = players.any(
          (existingPlayer) =>
      existingPlayer.name.trim().toLowerCase() ==
          name.toLowerCase(),
    );

    if (exists) {
      throw ArgumentError(
        'لا يمكن إضافة لاعب بنفس الاسم.',
      );
    }

    final normalizedPlayer = player.copyWith(
      name: name,
    );

    await repository.addPlayer(
      normalizedPlayer,
    );
  }
}