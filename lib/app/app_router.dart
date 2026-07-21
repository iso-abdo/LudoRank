import 'package:go_router/go_router.dart';



import 'package:ludo_rank/features/players/presentation/pages/players_page.dart';

import '../features/home/presentation/pages/home_page.dart';
import 'app_routes.dart';

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

  ],
);