import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:ludo_rank/core/dependency_injection/injection_container.dart';

import 'package:ludo_rank/features/matches/domain/entities/match.dart';
import 'package:ludo_rank/features/matches/domain/entities/match_status.dart';
import 'package:ludo_rank/features/match_players/domain/entities/match_player.dart';
import 'package:ludo_rank/features/matches/domain/usecases/create_match.dart';

import 'package:ludo_rank/features/tournament_players/presentation/providers/tournament_player_provider.dart';
import 'package:ludo_rank/features/players/presentation/providers/player_provider.dart';
import 'package:ludo_rank/shared/widgets/app_scaffold.dart';

class CreateMatchPage extends StatefulWidget {
  final String tournamentId;

  const CreateMatchPage({
    super.key,
    required this.tournamentId,
  });

  @override
  State<CreateMatchPage> createState() => _CreateMatchPageState();
}

class _CreateMatchPageState extends State<CreateMatchPage> {
  final TournamentPlayerProvider tournamentPlayerProvider =
      sl<TournamentPlayerProvider>();

  final CreateMatch createMatch =
      sl<CreateMatch>();
  final PlayerProvider playerProvider =
      sl<PlayerProvider>();
  final Uuid uuid = const Uuid();

  int? _playersCount;

  final Set<String> _selectedPlayerIds = {};

  bool _isCreating = false;

  @override
  void initState() {
    super.initState();

    tournamentPlayerProvider.loadPlayers(
      widget.tournamentId,
    );
    playerProvider.loadPlayers();

  }

  void _selectPlayersCount(int count) {
    setState(() {
      _playersCount = count;

      // لو غيرنا عدد اللاعبين،
      // نمسح الاختيارات القديمة حتى لا تصبح غير صالحة.
      _selectedPlayerIds.clear();
    });
  }

  void _togglePlayer(String playerId) {
    if (_playersCount == null) {
      return;
    }

    setState(() {
      if (_selectedPlayerIds.contains(playerId)) {
        _selectedPlayerIds.remove(playerId);
        return;
      }

      if (_selectedPlayerIds.length >= _playersCount!) {
        return;
      }

      _selectedPlayerIds.add(playerId);
    });
  }

  bool get _canCreateMatch {
    return _playersCount != null &&
        _selectedPlayerIds.length == _playersCount &&
        !_isCreating;
  }

  Future<void> _createNewMatch() async {
    if (!_canCreateMatch) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final now = DateTime.now();

      final match = Match(
        id: uuid.v4(),
        tournamentId: widget.tournamentId,
        playersCount: _playersCount!,
        status: MatchStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      final selectedPlayers =
      _selectedPlayerIds.toList();

      final matchPlayers = <MatchPlayer>[];

      for (var i = 0; i < selectedPlayers.length; i++) {
        matchPlayers.add(
          MatchPlayer(
            id: uuid.v4(),
            matchId: match.id,
            playerId: selectedPlayers[i],
            seat: i + 1,
            rank: null,
            points: 0,
            finished: false,
          ),
        );
      }

      await createMatch(
        match: match,
        players: matchPlayers,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إنشاء المباراة بنجاح'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'فشل إنشاء المباراة: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'إنشاء مباراة',
      body: ListenableBuilder(
        listenable: tournamentPlayerProvider,
        builder: (context, _) {
          if (tournamentPlayerProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (tournamentPlayerProvider.error != null) {
            return Center(
              child: Text(
                tournamentPlayerProvider.error!,
              ),
            );
          }

          final players =
              tournamentPlayerProvider.players;

          if (players.isEmpty) {
            return const Center(
              child: Text(
                'لا يوجد لاعبين داخل البطولة',
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'عدد اللاعبين في المباراة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _PlayersCountButton(
                        count: 2,
                        selected:
                        _playersCount == 2,
                        onTap: () {
                          _selectPlayersCount(2);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PlayersCountButton(
                        count: 3,
                        selected:
                        _playersCount == 3,
                        onTap: () {
                          _selectPlayersCount(3);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PlayersCountButton(
                        count: 4,
                        selected:
                        _playersCount == 4,
                        onTap: () {
                          _selectPlayersCount(4);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                if (_playersCount == null)
                  const Text(
                    'اختار عدد اللاعبين أولاً',
                    textAlign: TextAlign.center,
                  ),

                if (_playersCount != null) ...[
                  Text(
                    'اختار $_playersCount لاعبين',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  ...players.map(
                        (tournamentPlayer) {
                      final playerId =
                          tournamentPlayer.playerId;

                      final selected =
                      _selectedPlayerIds
                          .contains(playerId);

                      final disabled =
                          !selected &&
                              _selectedPlayerIds.length >=
                                  _playersCount!;

                      return Card(
                        child: CheckboxListTile(
                          value: selected,
                          onChanged: disabled
                              ? null
                              : (_) {
                            _togglePlayer(
                              playerId,
                            );
                          },
                          title: Text(
                            playerProvider.getPlayerName(playerId),
                          ),
                          subtitle: Text(
                            'المقعد: ${selected ? _getSeat(playerId) : '-'}',
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'تم اختيار ${_selectedPlayerIds.length} '
                        'من $_playersCount',
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    onPressed: _canCreateMatch
                        ? _createNewMatch
                        : null,
                    icon: _isCreating
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(
                      Icons.add,
                    ),
                    label: Text(
                      _isCreating
                          ? 'جاري إنشاء المباراة...'
                          : 'إنشاء المباراة',
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  int _getSeat(String playerId) {
    final index = _selectedPlayerIds
        .toList()
        .indexOf(playerId);

    return index == -1 ? 0 : index + 1;
  }
}

class _PlayersCountButton extends StatelessWidget {
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _PlayersCountButton({
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
        ),
      ),
      child: Text(
        '$count لاعبين',
      ),
    );
  }
}