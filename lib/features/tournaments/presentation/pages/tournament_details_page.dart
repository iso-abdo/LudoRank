import 'package:flutter/material.dart';
import 'package:ludo_rank/features/tournaments/presentation/providers/tournament_provider.dart';
import 'package:ludo_rank/shared/widgets/app_scaffold.dart';

import 'package:ludo_rank/core/dependency_injection/injection_container.dart';

import 'package:ludo_rank/features/tournament_players/domain/entities/tournament_player.dart';
import 'package:ludo_rank/features/tournament_players/presentation/providers/tournament_player_provider.dart';

import 'package:ludo_rank/features/tournament_players/presentation/pages/select_players_page.dart';

import 'package:uuid/uuid.dart';

class TournamentDetailsPage extends StatefulWidget {
  final String tournamentId;

  const TournamentDetailsPage({
    super.key,
    required this.tournamentId,
  });

  @override
  State<TournamentDetailsPage> createState() => _TournamentDetailsPageState();
}

class _TournamentDetailsPageState extends State<TournamentDetailsPage> {
  final TournamentPlayerProvider tournamentPlayerProvider =
      sl<TournamentPlayerProvider>();
  final TournamentProvider tournamentProvider =
      sl<TournamentProvider>();

  final uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    tournamentPlayerProvider.loadPlayers(
      widget.tournamentId,

    );
    tournamentProvider.loadTournament(
        widget.tournamentId);
  }

  Future<void> _addPlayers() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectPlayersPage(
          tournamentId: widget.tournamentId,
        ),
      ),
    );

    if (result == null || result.isEmpty) {
      return;
    }

    for (final playerId in result) {
      await tournamentPlayerProvider.addPlayer(
        TournamentPlayer(
          id: uuid.v4(),
          tournamentId: widget.tournamentId,
          playerId: playerId,
          joinedAt: DateTime.now(),
        ),
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "تفاصيل البطولة",
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Tournament ID",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      widget.tournamentId,
                      textAlign: TextAlign.center,
                    ),
                    const Divider(height: 32),
                    const ListTile(
                      leading: Icon(Icons.flag),
                      title: Text("الحالة"),
                      trailing: Chip(
                        label: Text("Draft"),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: tournamentPlayerProvider,
                      builder: (context, _) {
                        return ListTile(
                          leading: const Icon(Icons.people),
                          title: const Text("اللاعبون"),
                          trailing: Text("${tournamentPlayerProvider.players.length}"),
                        );
                      },
                    ),
                    const ListTile(
                      leading: Icon(Icons.sports_esports),
                      title: Text("المباريات"),
                      trailing: Text("0"),
                    ),
                    const ListTile(
                      leading: Icon(Icons.repeat),
                      title: Text("الجولات"),
                      trailing: Text("0"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ListenableBuilder(
              listenable: tournamentPlayerProvider,
              builder: (context, index) {
                if (tournamentPlayerProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (tournamentPlayerProvider.players.isEmpty) {
                  return const Center(
                    child: Text(
                      "لا يوجد لاعبون داخل البطولة",
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tournamentPlayerProvider.players.length,
                  itemBuilder: (_, index) {
                    final player = tournamentPlayerProvider.players[index];

                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(player.playerId),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _addPlayers,
              icon: const Icon(Icons.group_add),
              label: const Text("إضافة لاعبين"),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.play_arrow),
              label: const Text("استكمال البطولة"),
            ),
          ],
        ),
      ),
    );
  }
}
