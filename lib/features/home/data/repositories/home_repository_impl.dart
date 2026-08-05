import 'package:ludo_rank/features/home/data/data_sources/local/home_dao.dart';
import 'package:ludo_rank/features/home/data/models/dashboard_summary_model.dart';
import 'package:ludo_rank/features/home/domain/entities/dashboard_summary.dart';
import 'package:ludo_rank/features/home/domain/repositories/home_repository.dart';

class HomeRepositoryImpl
    implements HomeRepository {

  final HomeDao dao;

  HomeRepositoryImpl(this.dao);

  @override
  Future<DashboardSummary> getDashboardSummary() async {
    final playersCount =
    await dao.getPlayersCount();

    final tournamentsCount =
    await dao.getTournamentsCount();

    final matchesCount =
    await dao.getMatchesCount();

    final finishedCount =
    await dao.getFinishedTournamentsCount();

    return DashboardSummaryModel(
      playersCount: playersCount,
      tournamentsCount: tournamentsCount,
      matchesCount: matchesCount,
      finishedTournamentsCount: finishedCount,
    );
  }
}