import '../entities/dashboard_summary.dart';
import '../repositories/home_repository.dart';

class GetDashboard {
  final HomeRepository repository;

  GetDashboard(
      this.repository,
      );

  Future<DashboardSummary> call() {
    return repository.getDashboardSummary();
  }
}