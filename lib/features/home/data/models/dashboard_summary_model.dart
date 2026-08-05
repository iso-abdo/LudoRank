import 'package:ludo_rank/features/home/domain/entities/dashboard_summary.dart';

class DashboardSummaryModel extends DashboardSummary {
  const DashboardSummaryModel({
    required super.playersCount,
    required super.tournamentsCount,
    required super.matchesCount,
    required super.finishedTournamentsCount,
  });

  factory DashboardSummaryModel.fromEntity(
      DashboardSummary entity,
      ) {
    return DashboardSummaryModel(
      playersCount: entity.playersCount,
      tournamentsCount: entity.tournamentsCount,
      matchesCount: entity.matchesCount,
      finishedTournamentsCount: entity.finishedTournamentsCount,
    );
  }
}