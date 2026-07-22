import 'package:flutter/material.dart';

import 'package:ludo_rank/features/tournaments/domain/entities/tournament.dart';
import 'package:ludo_rank/features/tournaments/domain/repositories/tournament_repository.dart';

class TournamentProvider extends ChangeNotifier {
  final TournamentRepository repository;

  TournamentProvider(this.repository);

  final List<Tournament> _tournaments = [];

  List<Tournament> get tournaments => List.unmodifiable(_tournaments);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadTournaments() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await repository.getAllTournaments();

      _tournaments
        ..clear()
        ..addAll(result);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTournament(Tournament tournament) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await repository.addTournament(tournament);

      await loadTournaments();
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