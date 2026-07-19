import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ludo_rank/app/app_provider.dart';
import 'package:ludo_rank/app/app_router.dart';

class LudoRankApp extends StatelessWidget {
  const LudoRankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: AppProviders.providers,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
      ),
    );
  }
}