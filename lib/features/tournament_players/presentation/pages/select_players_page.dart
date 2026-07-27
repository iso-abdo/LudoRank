import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ludo_rank/shared/widgets/app_scaffold.dart';
import 'package:ludo_rank/shared/widgets/app_loading.dart';
import 'package:ludo_rank/shared/widgets/app_empty_state.dart';

import 'package:ludo_rank/features/players/domain/entities/player.dart';
import 'package:ludo_rank/features/players/presentation/providers/player_provider.dart';

class SelectPlayersPage extends StatefulWidget {
  final String tournamentId;

  const SelectPlayersPage({
    super.key,
    required this.tournamentId,
  });

  @override
  State<SelectPlayersPage> createState() =>
      _SelectPlayersPageState();
}

class _SelectPlayersPageState
    extends State<SelectPlayersPage> {

  final Set<String> selectedPlayers = {};

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
          title: "اختيار اللاعبين",

          body: _buildBody(provider),
        );
      },
    );
  }

  Widget _buildBody(
      PlayerProvider provider,
      ) {

    if (provider.isLoading) {
      return const AppLoading();
    }

    if (provider.players.isEmpty) {
      return const AppEmptyState(
        icon: Icons.people_outline,
        title: "لا يوجد لاعبون",
        subtitle: "قم بإضافة لاعبين أولاً",
      );
    }

    return Column(
      children: [

        Expanded(
          child: ListView.builder(
            itemCount: provider.players.length,

            itemBuilder: (_, index) {

              final Player player =
              provider.players[index];

              final selected =
              selectedPlayers.contains(player.id);

              return CheckboxListTile(

                value: selected,

                title: Text(player.name),

                subtitle: Text(
                  player.nickname ?? "",
                ),

                onChanged: (_) {

                  setState(() {

                    if (selected) {
                      selectedPlayers.remove(player.id);
                    } else {
                      selectedPlayers.add(player.id);
                    }

                  });

                },
              );
            },
          ),
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),

            child: FilledButton.icon(

              onPressed: () {

                Navigator.pop(
                  context,
                  selectedPlayers.toList(),
                );

              },

              icon: const Icon(Icons.check),

              label: Text(
                "حفظ (${selectedPlayers.length})",
              ),
            ),
          ),
        ),

      ],
    );
  }
}