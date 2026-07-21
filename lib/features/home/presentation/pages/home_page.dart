import 'package:flutter/material.dart';
import 'package:ludo_rank/app/app_routes.dart';
import 'package:ludo_rank/features/players/presentation/widgets/app_loading.dart';
import 'package:provider/provider.dart';

import 'package:ludo_rank/shared/widgets/app_scaffold.dart';

import 'package:ludo_rank/features/home/presentation/providers/home_provider.dart';
import 'package:ludo_rank/features/home/presentation/widgets/dashboard_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        return AppScaffold(
          title: 'LudoRank',

          body: provider.isLoading
              ? const AppLoading()
              : SingleChildScrollView(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                ElevatedButton.icon(
                  onPressed: () {

                  },
                  icon: const Icon(Icons.emoji_events),
                  label: const Text(
                    'إنشاء بطولة جديدة',
                  ),
                ),

                const SizedBox(height: 24),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,

                  children: [

                    DashboardCard(
                      icon: Icons.people,
                      title: 'اللاعبون',
                      value: provider.playersCount,
                      onTap: () {
                        context.push(AppRoutes.players);
                      },
                    ),

                    DashboardCard(
                      icon: Icons.emoji_events,
                      title: 'البطولات',
                      value: provider.tournamentsCount,
                    ),

                    DashboardCard(
                      icon: Icons.sports_esports,
                      title: 'المباريات',
                      value: provider.matchesCount,
                    ),

                    DashboardCard(
                      icon: Icons.workspace_premium,
                      title: 'بطولات منتهية',
                      value: provider.finishedTournamentsCount,
                    ),

                  ],
                ),

                const SizedBox(height: 24),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          'آخر بطولة',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'لا توجد بطولة حالياً',
                        ),

                      ],
                    ),
                  ),
                ),

              ],
            ),
          ),
        );
      },
    );
  }
}