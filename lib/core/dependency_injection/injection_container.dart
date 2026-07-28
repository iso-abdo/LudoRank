import 'package:get_it/get_it.dart';

import 'package:ludo_rank/core/database/database.dart';

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

}
