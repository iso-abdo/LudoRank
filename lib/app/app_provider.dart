import 'package:ludo_rank/features/matches/presentation/providers/match_provider.dart';
import 'package:provider/provider.dart';

import 'package:ludo_rank/core/dependency_injection/injection_container.dart';

import 'package:ludo_rank/features/home/presentation/providers/home_provider.dart';
import 'package:ludo_rank/features/players/presentation/providers/player_provider.dart';
import 'package:ludo_rank/features/tournaments/presentation/providers/tournament_provider.dart';
import 'package:ludo_rank/features/tournament_players/presentation/providers/tournament_player_provider.dart';

class AppProviders {
  static final providers = [
    ChangeNotifierProvider<HomeProvider>(
      create: (_) => sl<HomeProvider>(),
    ),
    ChangeNotifierProvider<PlayerProvider>(
      create: (_) => sl<PlayerProvider>(),
    ),
    ChangeNotifierProvider<TournamentProvider>(
      create: (_) => sl<TournamentProvider>(),
    ),
    ChangeNotifierProvider<TournamentPlayerProvider>(
      create: (_) => sl<TournamentPlayerProvider>(),
    ),
   ChangeNotifierProvider<MatchProvider>(
      create: (_) => sl<MatchProvider>(),
    ),
  ];
}
