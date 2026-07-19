import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/player_provider.dart';

import '../../domain/entities/player.dart';

import 'package:ludo_rank/features/players/presentation/widgets/app_app_bar.dart';
import 'package:ludo_rank/features/players/presentation/widgets/app_empty_state.dart';
import 'package:ludo_rank/features/players/presentation/widgets/app_error_widget.dart';
import 'package:ludo_rank/features/players/presentation/widgets/app_loading.dart';
import 'package:ludo_rank/features/players/presentation/widgets/app_scaffold.dart';
import 'package:ludo_rank/features/players/presentation/widgets/add_player_dialog.dart';

class PlayersPage extends StatefulWidget {
  const PlayersPage({super.key});

  @override
  State<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends State<PlayersPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlayerProvider>().loadPlayers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, child) {
        return AppScaffold(
          appBar: const AppAppBar(
            title: 'اللاعبون',
          ),

          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (_) => const AddPlayerDialog(),
              );
            },
            child: const Icon(Icons.add),
          ),

          body: _buildBody(provider),
        );
      },
    );
  }

  Widget _buildBody(PlayerProvider provider) {
    if (provider.isLoading) {
      return const AppLoading();
    }

    if (provider.error != null) {
      return AppErrorView(
        message: provider.error!,
        onRetry: provider.loadPlayers,
      );
    }

    if (provider.players.isEmpty) {
      return const AppEmptyState(
        icon: Icons.people_outline,
        title: "لا يوجد لاعبون",
        subtitle: "اضغط على زر + لإضافة أول لاعب",
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.players.length,
      separatorBuilder: (context, index) {
        return const SizedBox(height: 12);
      },
      itemBuilder: (context, index) {
        final Player player = provider.players[index];

        return Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text(player.name),
            subtitle: Text(
              player.nickname ?? "",
            ),
            trailing: player.isActive
                ? const Icon(
              Icons.check_circle,
              color: Colors.green,
            )
                : const Icon(
              Icons.cancel,
              color: Colors.red,
            ),
          ),
        );
      },
    );
  }
}