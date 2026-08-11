import 'package:get_it/get_it.dart';

import 'package:ludo_rank/core/database/database.dart';
import 'package:ludo_rank/features/home/data/data_sources/local/home_dao.dart';
import 'package:ludo_rank/features/home/data/repositories/home_repository_impl.dart';
import 'package:ludo_rank/features/home/domain/repositories/home_repository.dart';
import 'package:ludo_rank/features/home/domain/use_cases/get_dashboard.dart';
import 'package:ludo_rank/features/home/presentation/providers/home_provider.dart';
import 'package:ludo_rank/features/match_players/data/data_sources/local/match_player_dao.dart';
import 'package:ludo_rank/features/match_players/data/repositories/match_player_repository_impl.dart';
import 'package:ludo_rank/features/match_players/domain/repositories/match_player_repository.dart';
import 'package:ludo_rank/features/match_players/presentation/providers/match_player_provider.dart';


import 'package:ludo_rank/features/players/data/data_sources/local/player_dao.dart';
import 'package:ludo_rank/features/players/data/repositories/player_repository_impl.dart';

import 'package:ludo_rank/features/players/domain/repositories/player_repository.dart';

import 'package:ludo_rank/features/players/presentation/providers/player_provider.dart';
import 'package:ludo_rank/features/tournaments/data/data_sources/local/tournament_dao.dart';
// أضف الـ imports الخاصة بالـ tournament

import 'package:ludo_rank/features/tournaments/data/repositories/tournament_repository_impl.dart';

import 'package:ludo_rank/features/tournaments/domain/repositories/tournament_repository.dart';
import 'package:ludo_rank/features/tournaments/domain/services/tournament_validator.dart';
import 'package:ludo_rank/features/tournaments/domain/usecases/continue_tournament.dart';
import 'package:ludo_rank/features/tournaments/presentation/providers/tournament_provider.dart';

// Tournament Players.
import 'package:ludo_rank/features/tournament_players/data/data_sources/local/tournament_player_dao.dart';
import 'package:ludo_rank/features/tournament_players/data/repositories/tournament_player_repository_impl.dart';
import 'package:ludo_rank/features/tournament_players/domain/repositories/tournament_player_repository.dart';
import 'package:ludo_rank/features/tournament_players/presentation/providers/tournament_player_provider.dart';
// Match
import 'package:ludo_rank/features/matches/data/data_sources/local/match_dao.dart';
import 'package:ludo_rank/features/matches/data/repositories/match_repository_impl.dart';
import 'package:ludo_rank/features/matches/domain/repositories/match_repository.dart';
import 'package:ludo_rank/features/matches/presentation/providers/match_provider.dart';


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

  sl.registerLazySingleton(
        () => ContinueTournament(
      sl(),
      sl(),
      sl(),
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
  sl.registerLazySingleton<MatchDao>(
        () => MatchDao(sl<AppDatabase>()),

  );
  sl.registerLazySingleton<MatchPlayerDao>(
        () => MatchPlayerDao(sl<AppDatabase>()),
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
  sl.registerLazySingleton<MatchRepository>(
        () => MatchRepositoryImpl(
      sl<MatchDao>(),
    ),
  );
  sl.registerLazySingleton<MatchPlayerRepository>(
        () => MatchPlayerRepositoryImpl(
      sl<MatchPlayerDao>(),
    ),
  );


  // تأكد من وجود هذا السطر الخاص بـ MatchRepository (إذا لم يكن موجوداً)
  //sl.registerLazySingleton<MatchRepository>(() => MatchRepositoryImpl(sl()));


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

  sl.registerFactory<MatchProvider>(
        () => MatchProvider(
      sl<MatchRepository>(),
    ),
  );
  sl.registerFactory<MatchPlayerProvider>(
        () => MatchPlayerProvider(
      sl<MatchPlayerRepository>(),
    ),
  );


  // Validator
  sl.registerLazySingleton<TournamentValidator>(
        () => TournamentValidator(),
  );




}
