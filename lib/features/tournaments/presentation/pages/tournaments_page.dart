import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:ludo_rank/shared/widgets/app_scaffold.dart';
import 'package:ludo_rank/shared/widgets/app_loading.dart';
import 'package:ludo_rank/shared/widgets/app_empty_state.dart';
import 'package:ludo_rank/shared/widgets/app_error_widget.dart';

import 'package:ludo_rank/features/tournaments/presentation/providers/tournament_provider.dart';
import 'package:ludo_rank/features/tournaments/presentation/widgets/tournament_card.dart';
import 'package:ludo_rank/features/tournaments/presentation/widgets/create_tournament_dialog.dart';

import '../../../../app/app_routes.dart';

class TournamentsPage extends StatefulWidget {
  const TournamentsPage({super.key});

  @override
  State<TournamentsPage> createState() => _TournamentsPageState();
}

class _TournamentsPageState extends State<TournamentsPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TournamentProvider>().loadTournaments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TournamentProvider>(
      builder: (context, provider, child) {
        return AppScaffold(
          title: 'البطولات',

          floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (_) => const CreateTournamentDialog(),
              );
            },
          ),

          body: _buildBody(provider),
        );
      },
    );
  }

  Widget _buildBody(TournamentProvider provider) {
    if (provider.isLoading) {
      return const AppLoading();
    }

    if (provider.error != null) {
      return AppErrorWidget(
        message: provider.error!,
        onRetry: provider.loadTournaments,
      );
    }

    if (provider.tournaments.isEmpty) {
      return const AppEmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'لا توجد بطولات',
        subtitle: 'اضغط + لإنشاء أول بطولة',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),

      itemCount: provider.tournaments.length,

      separatorBuilder: (context, index) {
        return const SizedBox(height: 12);
      },

        itemBuilder: (_, index) {
          final tournament = provider.tournaments[index];

          return TournamentCard(
            tournament: tournament,
            onTap: () {
              context.push(
                '${AppRoutes.tournaments}/${tournament.id}',
              );
            },
          );
        }
    );
  }
}