import 'package:flutter/material.dart';

import 'package:ludo_rank/features/home/domain/entities/dashboard_summary.dart';
import 'package:ludo_rank/features/home/domain/use_cases/get_dashboard.dart';

class HomeProvider extends ChangeNotifier {
  final GetDashboard getDashboard;

  HomeProvider(this.getDashboard);

  DashboardSummary? _dashboard;

  DashboardSummary? get dashboard => _dashboard;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  String? _error;

  String? get error => _error;

  Future<void> loadDashboard() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _dashboard = await getDashboard();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int get playersCount =>
      _dashboard?.playersCount ?? 0;

  int get tournamentsCount =>
      _dashboard?.tournamentsCount ?? 0;

  int get matchesCount =>
      _dashboard?.matchesCount ?? 0;

  int get finishedTournamentsCount =>
      _dashboard?.finishedTournamentsCount ?? 0;

  void clearError() {
    _error = null;
    notifyListeners();
  }
}