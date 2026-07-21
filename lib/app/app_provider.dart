import 'package:provider/provider.dart';

import 'package:ludo_rank/core/dependency_injection/injection_container.dart';

import 'package:ludo_rank/features/home/presentation/providers/home_provider.dart';
import 'package:ludo_rank/features/players/presentation/providers/player_provider.dart';

class AppProviders {
  static final providers = [
    ChangeNotifierProvider<HomeProvider>(
      create: (_) => HomeProvider(),
    ),

    ChangeNotifierProvider<PlayerProvider>(
      create: (_) => sl<PlayerProvider>(),
    ),
  ];
}