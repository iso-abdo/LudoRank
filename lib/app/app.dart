
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ludo_rank/app/app_provider.dart';
import 'package:ludo_rank/app/app_router.dart';
import 'package:ludo_rank/app/theme_controller.dart';
import 'package:ludo_rank/core/theme/app_theme.dart';

class LudoRankApp extends StatelessWidget {
  const LudoRankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: AppProviders.providers,
      child: Consumer<ThemeController>(
        builder: (context, themeController, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            routerConfig: appRouter,

            // Light and Dark Themes
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,

            // Current Theme Mode
            themeMode: themeController.themeMode,
          );
        },
      ),
    );
  }
}
