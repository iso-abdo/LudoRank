
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ludo_rank/app/theme_controller.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  const AppAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: centerTitle,
      leading: leading,
      actions: [
        ...?actions,
        Consumer<ThemeController>(
          builder: (context, themeController, child) {
            //final isDark =
              //  themeController.themeMode == ThemeMode.dark;
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
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
