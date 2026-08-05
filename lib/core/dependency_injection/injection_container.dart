import 'package:get_it/get_it.dart';

import 'package:ludo_rank/core/database/database.dart';
import 'package:ludo_rank/features/home/data/data_sources/local/home_dao.dart';
import 'package:ludo_rank/features/home/data/repositories/home_repository_impl.dart';
import 'package:ludo_rank/features/home/domain/repositories/home_repository.dart';
import 'package:ludo_rank/features/home/domain/use_cases/get_dashboard.dart';
import 'package:ludo_rank/features/home/presentation/providers/home_provider.dart';

import 'package:ludo_rank/features/players/data/data_sources/local/player_dao.dart';
import 'package:ludo_rank/features/players/data/repositories/player_repository_impl.dart';

import 'package:ludo_rank/features/players/domain/repositories/player_repository.dart';

import 'package:ludo_rank/features/players/presentation/providers/player_provider.dart';
import 'package:ludo_rank/features/tournaments/data/data_sources/local/tournament_dao.dart';
// أضف الـ imports الخاصة بالـ tournament

import 'package:ludo_rank/features/tournaments/data/repositories/tournament_repository_impl.dart';

import 'package:ludo_rank/features/tournaments/domain/repositories/tournament_repository.dart';
import 'package:ludo_rank/features/tournaments/presentation/providers/tournament_provider.dart';

// Tournament Players.
import 'package:ludo_rank/features/tournament_players/data/data_sources/local/tournament_player_dao.dart';
import 'package:ludo_rank/features/tournament_players/data/repositories/tournament_player_repository_impl.dart';
import 'package:ludo_rank/features/tournament_players/domain/repositories/tournament_player_repository.dart';
import 'package:ludo_rank/features/tournament_players/presentation/providers/tournament_player_provider.dart';


final sl = GetIt.instance;


Future<void> initDependencies() async {

  // Database

  sl.registerLazySingleton<AppDatabase>(
        () => AppDatabase(),
  );

  // UseCase
  sl.registerLazySingleton<GetDashboard>(
        () => GetDashboard(
      sl<HomeRepository>(),
    ),
  );
  // DAO

  sl.registerLazySingleton<PlayerDao>(
        () => PlayerDao(
      sl<AppDatabase>(),
    ),
  );
  sl.registerLazySingleton<TournamentDao>(
        () => TournamentDao(
      sl<AppDatabase>(),
    ),
  );
  sl.registerLazySingleton<TournamentPlayerDao>(
        () => TournamentPlayerDao(
      sl<AppDatabase>(),
    ),
  );
  sl.registerLazySingleton<HomeDao>(
        () => HomeDao(sl<AppDatabase>()),
  );



  // Repository

  sl.registerLazySingleton<PlayerRepository>(
        () => PlayerRepositoryImpl(
      sl<PlayerDao>(),
    ),
  );
  sl.registerLazySingleton<TournamentRepository>(
        () => TournamentRepositoryImpl(
      sl<TournamentDao>(),
    ),
  );
  sl.registerLazySingleton<TournamentPlayerRepository>(
        () => TournamentPlayerRepositoryImpl(
      sl<TournamentPlayerDao>(),
    ),
  );
  sl.registerLazySingleton<HomeRepository>(
        () => HomeRepositoryImpl(
      sl<HomeDao>(),
    ),
  );



  // Provider

  sl.registerFactory<PlayerProvider>(
        () => PlayerProvider(
      sl<PlayerRepository>(),
    ),
  );

  sl.registerFactory<TournamentProvider>(
    () => TournamentProvider(
      sl<TournamentRepository>(),
    ),
  );
  sl.registerFactory<TournamentPlayerProvider>(
    () => TournamentPlayerProvider(
      sl<TournamentPlayerRepository>(),
    ),
  );
  sl.registerFactory<HomeProvider>(
    () => HomeProvider(
      sl<GetDashboard>(),
    ),
  );

}
