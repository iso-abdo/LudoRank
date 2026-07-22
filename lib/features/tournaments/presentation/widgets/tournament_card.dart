import 'package:flutter/material.dart';

import 'package:ludo_rank/features/tournaments/domain/entities/tournament.dart';
// tournament_status_extension.dart
import 'package:ludo_rank/features/tournaments/presentation/extensions/tournament_status_extension.dart';
class TournamentCard extends StatelessWidget {
  final Tournament tournament;

  final VoidCallback? onTap;

  const TournamentCard({
    super.key,
    required this.tournament,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,

      child: InkWell(
        borderRadius: BorderRadius.circular(12),

        onTap: onTap,

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Row(
                children: [

                  const Icon(
                    Icons.emoji_events,
                    size: 28,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      tournament.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium,
                    ),
                  ),

                ],
              ),

              const SizedBox(height: 16),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [

                  Chip(
                    avatar: Icon(
                      tournament.status.icon,
                      size: 18,
                      color: tournament.status.color,
                    ),

                    label: Text(
                      tournament.status.title,
                    ),

                    side: BorderSide(
                      color: tournament.status.color,
                    ),
                  ),

                  Chip(
                    avatar: const Icon(
                      Icons.layers,
                      size: 18,
                    ),
                    label: Text(
                      "${tournament.rounds} جولة",
                    ),
                  ),

                ],
              ),

              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerRight,

                child: FilledButton.icon(
                  onPressed: onTap,

                  icon: const Icon(
                    Icons.play_arrow,
                  ),

                  label: const Text(
                    "استكمال",
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}