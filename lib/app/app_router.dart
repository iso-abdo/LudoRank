import 'package:go_router/go_router.dart';



import 'package:ludo_rank/features/players/presentation/pages/players_page.dart';

import '../features/home/presentation/pages/home_page.dart';
import '../features/tournaments/presentation/pages/tournament_details_page.dart';
import 'app_routes.dart';
import 'package:ludo_rank/features/tournaments/presentation/pages/tournaments_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,

  routes: [
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),

    GoRoute(
      path: AppRoutes.players,
      name: 'players',

      builder: (context, state) {
        return const PlayersPage();
      },
    ),

    GoRoute(
      path: AppRoutes.tournaments,
      name: 'tournaments',
      builder: (context, state) => const TournamentsPage(),
    ),

    GoRoute(
      path: '${AppRoutes.tournaments}/:id',

      name: 'tournament-details',

      builder: (context, state) {
        final id = state.pathParameters['id']!;

        return TournamentDetailsPage(
          tournamentId: id,
        );
      },
    ),
  ],
);