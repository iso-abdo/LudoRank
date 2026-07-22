import 'package:get_it/get_it.dart';

import 'package:ludo_rank/core/database/database.dart';

import 'package:ludo_rank/features/players/data/data_sources/local/player_dao.dart';
import 'package:ludo_rank/features/players/data/repositories/player_repository_impl.dart';

import 'package:ludo_rank/features/players/domain/repositories/player_repository.dart';

import 'package:ludo_rank/features/players/presentation/providers/player_provider.dart';
// أضف الـ imports الخاصة بالـ tournament
import 'package:ludo_rank/features/tournaments/data/datasources/local/tournament_dao.dart';

import 'package:ludo_rank/features/tournaments/data/repositories/tournament_repository_impl.dart';

import 'package:ludo_rank/features/tournaments/domain/repositories/tournament_repository.dart';

import 'package:ludo_rank/features/tournaments/presentation/providers/tournament_provider.dart';

final sl = GetIt.instance;


Future<void> initDependencies() async {

  // Database

  sl.registerLazySingleton<AppDatabase>(
        () => AppDatabase(),
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
}