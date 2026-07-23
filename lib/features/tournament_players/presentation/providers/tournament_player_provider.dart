import 'package:flutter/material.dart';

import 'package:ludo_rank/features/tournament_players/domain/entities/tournament_player.dart';
import 'package:ludo_rank/features/tournament_players/domain/repositories/tournament_player_repository.dart';

class TournamentPlayerProvider extends ChangeNotifier {
  final TournamentPlayerRepository repository;

  TournamentPlayerProvider(
      this.repository,
      );

  final List<TournamentPlayer> _players = [];

  bool _isLoading = false;

  String? _error;

  List<TournamentPlayer> get players => _players;

  bool get isLoading => _isLoading;

  String? get error => _error;

  Future<void> loadPlayers(
      String tournamentId,
      ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _players
        ..clear()
        ..addAll(
          await repository.getTournamentPlayers(
            tournamentId,
          ),
        );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPlayer(
      TournamentPlayer player,
      ) async {
    await repository.addPlayer(player);

    await loadPlayers(
      player.tournamentId,
    );
  }

  Future<void> removePlayer(
      TournamentPlayer player,
      ) async {
    await repository.removePlayer(
      player.id,
    );

    await loadPlayers(
      player.tournamentId,
    );
  }
}