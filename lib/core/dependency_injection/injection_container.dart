import 'package:get_it/get_it.dart';

import 'package:ludo_rank/core/database/database.dart';

import 'package:ludo_rank/features/players/data/data_sources/local/player_dao.dart';
import 'package:ludo_rank/features/players/data/repositories/player_repository_impl.dart';

import 'package:ludo_rank/features/players/domain/repositories/player_repository.dart';

import 'package:ludo_rank/features/players/presentation/providers/player_provider.dart';


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


  // Repository

  sl.registerLazySingleton<PlayerRepository>(
        () => PlayerRepositoryImpl(
      sl<PlayerDao>(),
    ),
  );


  // Provider

  sl.registerFactory<PlayerProvider>(
        () => PlayerProvider(
      sl<PlayerRepository>(),
    ),
  );

}