
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ludo_rank/app/theme_controller.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final Widget? drawer;
  final Widget? bottomNavigationBar;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
    this.drawer,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        actions: [
          ...?actions,

          Consumer<ThemeController>(
            builder: (context, themeController, child) {
              //final isDark = themeController.themeMode == ThemeMode.dark;
              final isDark = Theme.of(context).brightness == Brightness.dark;

              return IconButton(
                tooltip: isDark ? 'الوضع الفاتح' : 'الوضع الداكن',
                icon: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                ),
                //onPressed: themeController.toggleTheme,
                onPressed: () async {
                  await themeController.setThemeMode(
                    isDark ? ThemeMode.light : ThemeMode.dark,
                  );
                },
              );
            },
          ),
        ],
      ),
      drawer: drawer,
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
