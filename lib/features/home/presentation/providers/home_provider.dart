import 'package:flutter/material.dart';

class HomeProvider extends ChangeNotifier {
  int _playersCount = 0;
  int _tournamentsCount = 0;
  int _matchesCount = 0;
  int _finishedTournamentsCount = 0;

  bool _isLoading = false;

  int get playersCount => _playersCount;
  int get tournamentsCount => _tournamentsCount;
  int get matchesCount => _matchesCount;
  int get finishedTournamentsCount => _finishedTournamentsCount;

  bool get isLoading => _isLoading;

  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();

    // TODO:
    // اقرأ البيانات من قاعدة البيانات
    // حاليا بيانات مؤقتة

    await Future.delayed(const Duration(milliseconds: 300));

    _playersCount = 0;
    _tournamentsCount = 0;
    _matchesCount = 0;
    _finishedTournamentsCount = 0;

    _isLoading = false;
    notifyListeners();
  }
}