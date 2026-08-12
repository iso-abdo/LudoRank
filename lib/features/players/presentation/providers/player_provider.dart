import 'package:flutter/material.dart';

import '../../domain/entities/player.dart';
import '../../domain/repositories/player_repository.dart';

class PlayerProvider extends ChangeNotifier {
  final PlayerRepository repository;

  PlayerProvider(this.repository);

  final List<Player> _players = [];

  // ============================================================
  // Getters
  // ============================================================

  List<Player> get players => List.unmodifiable(_players);

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  String? _error;

  String? get error => _error;

  // ============================================================
  // Player Lookup
  // ============================================================

  Player? getPlayerById(String id) {
    try {
      return _players.firstWhere(
            (player) => player.id == id,
      );
    } catch (_) {
      return null;
    }
  }

  String getPlayerName(String playerId) {
    return getPlayerById(playerId)?.name ?? 'لاعب غير معروف';
  }

  // ============================================================
  // Load Players
  // ============================================================

  Future<void> loadPlayers() async {
    try {
      _isLoading = true;
      _error = null;

      notifyListeners();

      final result = await repository.getAllPlayers();

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

  // ============================================================
  // Add Player
  // ============================================================

  Future<void> addPlayer(Player player) async {
    try {
      _isLoading = true;
      _error = null;

      notifyListeners();

      await repository.addPlayer(player);

      await loadPlayers();
    } catch (e) {
      _error = e.toString();

      _isLoading = false;

      notifyListeners();

      rethrow;
    }
  }

  // ============================================================
  // Update Player
  // ============================================================

  Future<void> updatePlayer(Player player) async {
    try {
      _isLoading = true;
      _error = null;

      notifyListeners();

      await repository.updatePlayer(player);

      await loadPlayers();
    } catch (e) {
      _error = e.toString();

      _isLoading = false;

      notifyListeners();

      rethrow;
    }
  }

  // ============================================================
  // Delete Player
  // ============================================================

  Future<void> deletePlayer(String id) async {
    try {
      _isLoading = true;
      _error = null;

      notifyListeners();

      await repository.deletePlayer(id);

      await loadPlayers();
    } catch (e) {
      _error = e.toString();

      _isLoading = false;

      notifyListeners();

      rethrow;
    }
  }

  // ============================================================
  // Error
  // ============================================================

  void clearError() {
    _error = null;

    notifyListeners();
  }
}