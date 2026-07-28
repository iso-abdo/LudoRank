/*import 'package:flutter/material.dart';

import '../../domain/entities/match.dart';
import '../../domain/repositories/match_repository.dart';

class MatchProvider extends ChangeNotifier {
  final MatchRepository repository;

  MatchProvider(this.repository);

  final List<Match> _matches = [];

  List<Match> get matches => List.unmodifiable(_matches);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadMatches(String tournamentId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await repository.getTournamentMatches(tournamentId);

      _matches
        ..clear()
        ..addAll(result);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMatch(Match match) async {
    try {
      _isLoading = true;
      notifyListeners();

      await repository.addMatch(match);

      await loadMatches(match.tournamentId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateMatch(Match match) async {
    try {
      _isLoading = true;
      notifyListeners();

      await repository.updateMatch(match);

      await loadMatches(match.tournamentId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteMatch(String id, String tournamentId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await repository.deleteMatch(id);

      await loadMatches(tournamentId);
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
}*/
