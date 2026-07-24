import 'package:flutter/material.dart';

import 'package:ludo_rank/features/match_players/domain/entities/match_player.dart';
import 'package:ludo_rank/features/match_players/domain/repositories/match_player_repository.dart';

class MatchPlayerProvider extends ChangeNotifier {
  final MatchPlayerRepository repository;

  MatchPlayerProvider(this.repository);

  final List<MatchPlayer> _players = [];

  List<MatchPlayer> get players =>
      List.unmodifiable(_players);

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  String? _error;

  String? get error => _error;

  Future<void> loadPlayers(
      String matchId,
      ) async {
    try {
      _isLoading = true;
      _error = null;

      notifyListeners();

      final result =
      await repository.getMatchPlayers(matchId);

      _players
        ..clear()
        ..addAll(result);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPlayer(
      MatchPlayer player,
      ) async {
    await repository.addPlayer(player);

    await loadPlayers(player.matchId);
  }

  Future<void> addPlayers(
      List<MatchPlayer> players,
      ) async {
    await repository.addPlayers(players);

    if (players.isNotEmpty) {
      await loadPlayers(players.first.matchId);
    }
  }

  Future<void> removePlayer(
      MatchPlayer player,
      ) async {
    await repository.removePlayer(player.id);

    await loadPlayers(player.matchId);
  }
}