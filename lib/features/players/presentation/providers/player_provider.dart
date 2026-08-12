import 'package:flutter/material.dart';
import '../../domain/entities/player.dart';
import '../../domain/repositories/player_repository.dart';

class PlayerProvider extends ChangeNotifier {
  final PlayerRepository repository;

  PlayerProvider(this.repository);

  final List<Player> _players = [];

  // 1. Getters (مستخرجات البيانات)
  List<Player> get players => List.unmodifiable(_players);
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _error;
  String? get error => _error;

  // المكان الأنسب للدالة الجديدة لتوحيد عمليات جلب وقراءة البيانات
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
  // 2. Actions / Futures (العمليات والمزامنة)
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

  Future<void> addPlayer(Player player) async {
    try {
      _isLoading = true;
      notifyListeners();
      await repository.addPlayer(player);
      await loadPlayers();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePlayer(Player player) async {
    try {
      _isLoading = true;
      notifyListeners();
      await repository.updatePlayer(player);
      await loadPlayers();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePlayer(String id) async {
    try {
      _isLoading = true;
      notifyListeners();
      await repository.deletePlayer(id);
      await loadPlayers();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
