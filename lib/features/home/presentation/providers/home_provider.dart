import 'package:flutter/material.dart';
import 'package:ludo_rank/features/home/domain/use_cases/get_dashboard.dart';

import '../../domain/entities/dashboard_summary.dart';


class HomeProvider extends ChangeNotifier {
  final GetDashboard getDashboard;

  HomeProvider(this.getDashboard);

  DashboardSummary? _dashboard;

  DashboardSummary? get dashboard => _dashboard;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> loadDashboard() async {
    try {
      _isLoading = true;
      notifyListeners();

      _dashboard = await getDashboard();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int get playersCount => _dashboard?.playersCount ?? 0;

  int get tournamentsCount => _dashboard?.tournamentsCount ?? 0;

  int get matchesCount => _dashboard?.matchesCount ?? 0;

  int get finishedTournamentsCount =>
      _dashboard?.finishedTournamentsCount ?? 0;
}