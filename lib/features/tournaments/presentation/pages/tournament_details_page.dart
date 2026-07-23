import 'package:flutter/material.dart';
import 'package:ludo_rank/shared/widgets/app_scaffold.dart';

class TournamentDetailsPage extends StatelessWidget {
  final String tournamentId;

  const TournamentDetailsPage({
    super.key,
    required this.tournamentId,
  });

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
                      tournamentId,
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

                    const ListTile(
                      leading: Icon(Icons.people),
                      title: Text("اللاعبون"),
                      trailing: Text("0"),
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

            ElevatedButton.icon(
              onPressed: () {

              },
              icon: const Icon(Icons.group_add),
              label: const Text("إضافة لاعبين"),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: () {

              },
              icon: const Icon(Icons.play_arrow),
              label: const Text("استكمال البطولة"),
            ),

          ],
        ),
      ),
    );
  }
}